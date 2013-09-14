use strictures 1;

package Object::Glib::Meta::Property::Type::Array;
use Moo;
use Carp qw( croak );
use Try::Tiny;
use Object::Glib::CarpGroup;

use aliased 'Object::Glib::Meta::Signal';

use namespace::clean;

extends 'Object::Glib::Meta::Property';

sub _build_property_signals {
    my ($self) = @_;
    return [
        defined($self->signals->{insert}) ? Signal->new(
            name => $self->_signal_name('insert'),
            arity => 2,
        ) : (),
        defined($self->signals->{update}) ? Signal->new(
            name => $self->_signal_name('update'),
            arity => 3,
        ) : (),
        defined($self->signals->{delete}) ? Signal->new(
            name => $self->_signal_name('delete'),
            arity => 2,
        ) : (),
    ];
}

sub _build_typed_builder { sub { [] } }

sub _build_signal_formats {
    return {
        insert => '%s_inserted',
        update => '%s_changed',
        delete => '%s_deleted',
    };
}

sub _build_constraint {
    my ($self) = @_;
    my $item_check = $self->item_constraint;
    return sub {
        my ($value) = @_;
        die "Not an array reference\n"
            unless ref $value eq 'ARRAY';
        return 1
            unless $item_check;
        my $last;
        try {
            for my $idx (0 .. $#$value) {
                $last = $idx;
                $item_check->($value->[ $idx ]);
            }
        }
        catch {
            my $err = $_;
            chomp $err;
            die "Index $last: $err\n";
        };
        return 1;
    };
}

sub _build_coercion {
    my ($self) = @_;
    my $item_coerce = $self->item_coercion;
    return undef
        unless $item_coerce;
    return sub {
        my ($value) = @_;
        die "Not an array reference\n"
            unless ref $value eq 'ARRAY';
        my $last;
        try {
            my @clean;
            for my $idx (0 .. $#$value) {
                $last = $idx;
                push @clean, scalar $item_coerce->($value->[ $idx ]);
            }
            $value = \@clean;
        }
        catch {
            my $err = $_;
            chomp $err;
            die "Index $last: $err\n";
        };
        return $value;
    };
}

sub _generate_count_delegation {
    my ($self, $meta) = @_;
    my $get = $self->getter_ref;
    return sub {
        return scalar @{ $_[0]->$get };
    };
}

sub _generate_all_delegation {
    my ($self, $meta) = @_;
    my $get = $self->getter_ref;
    return sub {
        return @{ $_[0]->$get };
    };
}

sub _generate_get_delegation {
    my ($self, $meta, @curry) = @_;
    my $get = $self->getter_ref;
    return sub {
        my $instance = shift;
        my ($index) = (@curry, @_);
        my $array = $instance->$get;
        return $array->[ $index ];
    };
}

sub _generate_get_all_delegation {
    my ($self, $meta, @curry) = @_;
    my $get = $self->getter_ref;
    return sub {
        my $instance = shift;
        my (@indices) = (@curry, @_);
        my $array = $instance->$get;
        return $array->[ $indices[0] ]
            if @indices == 1;
        return @{ $array }[ @indices ];
    };
}

sub _make_clearer {
    my ($self) = @_;
    my $name = $self->name;
    my $get = $self->getter_ref;
    return sub {
        my ($instance, $key) = @_;
        my $hash = $instance->$get;
        return undef
            unless exists $hash->{ $key };
    }
}

sub _generate_iv_delegation {
    my ($self, $meta) = @_;
    my $get = $self->getter_ref;
    return sub {
        my $instance = shift;
        my $array = $instance->$get;
        return map { [$_, $array->[ $_ ]] } 0 .. $#$array;
    };
}

sub _generate_shift_delegation {
    my ($self, $meta) = @_;
    my $get = $self->getter_ref;
    my $sig_delete = $self->_signal_name('delete');
    return sub {
        my $instance = shift;
        my $array = $instance->$get;
        return undef
            unless @$array;
        my $value = shift @$array;
        if (defined $sig_delete) {
            $instance->signal_emit($sig_delete, 0, $value);
        }
        return $value;
    };
}

sub _make_new_value_cleaner {
    my ($self, $id) = @_;
    my $name = $self->name;
    my $coerce = $self->item_coercion;
    my $check = $self->item_constraint;
    return sub {
        my ($instance, @values) = @_;
        my @clean;
        for my $index (0 .. $#values) {
            my $value = $values[ $index ];
            try {
                $value = $coerce->($value)
                    if $coerce;
                $check->($value)
                    if $check;
            }
            catch {
                my $err = $_;
                chomp $err;
                croak join ' ',
                    qq{Property '$name' $id item},
                    qq{$index value error: $err};
            };
            push @clean, $value;
        }
        return @clean;
    };
}

sub _generate_unshift_delegation {
    my ($self, $meta, @curry) = @_;
    my $get = $self->getter_ref;
    my $sig_insert = $self->_signal_name('insert');
    my $clean_values = $self->_make_new_value_cleaner('unshift');
    return sub {
        my $instance = shift;
        my $array = $instance->$get;
        my @clean = $instance->$clean_values(@curry, @_);
        for my $value (reverse @clean) {
            unshift @$array, $value;
            if (defined $sig_insert) {
                $instance->signal_emit($sig_insert, 0, $value);
            }
        }
        return 1;
    };
}

sub _generate_pop_delegation {
    my ($self, $meta) = @_;
    my $get = $self->getter_ref;
    my $sig_delete = $self->_signal_name('delete');
    return sub {
        my $instance = shift;
        my $array = $instance->$get;
        return undef
            unless @$array;
        my $index = $#$array;
        my $value = pop @$array;
        if (defined $sig_delete) {
            $instance->signal_emit($sig_delete, $index, $value);
        }
        return $value;
    };
}

sub _generate_push_delegation {
    my ($self, $meta, @curry) = @_;
    my $get = $self->getter_ref;
    my $sig_insert = $self->_signal_name('insert');
    my $clean_values = $self->_make_new_value_cleaner('push');
    return sub {
        my $instance = shift;
        my $array = $instance->$get;
        my @clean = $instance->$clean_values(@curry, @_);
        for my $value (@clean) {
            push @$array, $value;
            if (defined $sig_insert) {
                $instance->signal_emit($sig_insert, $#$array, $value);
            }
        }
        return 1;
    };
}

sub _make_item_setter {
    my ($self) = @_;
    my $get = $self->getter_ref;
    my $sig_change = $self->_signal_name('update');
    return sub {
        my ($instance, $index, $value) = @_;
        my $array = $instance->$get;
        my $old = $array->[ $index ];
        $array->[ $index ] = $value;
        if (defined $sig_change) {
            $instance->signal_emit($sig_change, $index, $value, $old);
        }
        return 1;
    };
}

sub _make_index_checker {
    my ($self) = @_;
    my $get = $self->getter_ref;
    return sub {
        my ($instance, $index) = @_;
        my $array = $instance->$get;
        croak sprintf q{Invalid index '%s'},
                defined($index) ? $index : '<undef>'
            unless defined($index)
            and $index >= 0
            and $index <= $#$array; 
        return 1;
    };
}

sub _generate_set_delegation {
    my ($self, $meta, @curry) = @_;
    my $name = $self->name;
    my $set_item = $self->_make_item_setter;
    my $check_idx = $self->_make_index_checker;
    my $coerce = $self->item_coercion;
    my $check = $self->item_constraint;
    return sub {
        my $instance = shift;
        my ($index, $value) = (@curry, @_);
        $instance->$check_idx($index);
        try {
            $value = $coerce->($value)
                if $coerce;
            $check->($value)
                if $check;
        }
        catch {
            my $err = $_;
            chomp $err;
            croak qq{Property '$name' index $index value error: $err};
        };
        $instance->$set_item($index, $value);
        return 1;
    };
}

sub _generate_set_all_delegation {
    my ($self, $meta, @curry) = @_;
    my $name = $self->name;
    my $set_item = $self->_make_item_setter;
    my $check_idx = $self->_make_index_checker;
    my $coerce = $self->item_coercion;
    my $check = $self->item_constraint;
    return sub {
        my $instance = shift;
        my @pairs;
        my (@values) = (@curry, @_);
        while (@values) {
            my $index = shift @values;
            $instance->$check_idx($index);
            my $value = shift @values;
            try {
                $value = $coerce->($value)
                    if $coerce;
                $check->($value)
                    if $check;
            }
            catch {
                my $err = $_;
                chomp $err;
                croak qq{Property '$name' index $index value error: $err};
            };
            push @pairs, [$index, $value];
        }
        $instance->$set_item(@$_)
            for @pairs;
        return 1;
    };
}

sub _generate_map_delegation {
    my ($self, $meta, @curry) = @_;
    my $get = $self->getter_ref;
    return sub {
        my $instance = shift;
        my ($code, @args) = (@curry, @_);
        my $array = $instance->$get;
        return map {
            local $_ = $_;
            $code->($_, @args);
        } @$array;
    };
}

sub _generate_grep_delegation {
    my ($self, $meta, @curry) = @_;
    my $get = $self->getter_ref;
    return sub {
        my $instance = shift;
        my ($code, @args) = (@curry, @_);
        my $array = $instance->$get;
        return grep {
            local $_ = $_;
            $code->($_, @args);
        } @$array;
    };
}

sub _generate_first_delegation {
    my ($self, $meta, @curry) = @_;
    my $get = $self->getter_ref;
    return sub {
        my $instance = shift;
        my ($code, @args) = (@curry, @_);
        my $array = $instance->$get;
        for my $value (@$array) {
            return $value if do {
                local $_ = $value;
                $code->($value, @args);
            };
        }
        return undef;
    };
}

sub _generate_first_index_delegation {
    my ($self, $meta, @curry) = @_;
    my $get = $self->getter_ref;
    return sub {
        my $instance = shift;
        my ($code, @args) = (@curry, @_);
        my $array = $instance->$get;
        for my $index (0 .. $#$array) {
            return $index if do {
                my $value = $array->[ $index ];
                local $_ = $value;
                $code->($value, @args);
            };
        }
        return undef;
    };
}

sub _generate_exists_delegation {
    my ($self, $meta, @curry) = @_;
    my $get = $self->getter_ref;
    return sub {
        my $instance = shift;
        my ($index) = (@curry, @_);
        my $array = $instance->$get;
        return $#$array >= $index ? 1 : 0;
    };
}

with qw(
    Object::Glib::Meta::Property::Typed::Container
);

1;
