use strictures 1;

package Object::Glib::Meta::Property::Type::Hash;
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

sub _build_typed_builder { sub { {} } }

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
        die "Not a hash reference\n"
            unless ref $value eq 'HASH';
        return 1
            unless $item_check;
        my $last;
        try {
            for my $key (keys %$value) {
                $last = $key;
                $item_check->($value->{ $key });
            }
        }
        catch {
            my $err = $_;
            chomp $err;
            die "Item '$last': $err\n";
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
        die "Not a hash reference\n"
            unless ref $value eq 'HASH';
        my $last;
        try {
            my %clean;
            for my $key (keys %$value) {
                $last = $key;
                $clean{ $key } = $item_coerce->($value->{ $key });
            }
            $value = \%clean;
        }
        catch {
            my $err = $_;
            chomp $err;
            die "Item '$last': $err\n";
        };
        return $value;
    };
}

sub _generate_map_pairs_delegation {
    my ($self, $meta, @curry) = @_;
    my $name = $self->name;
    my $get = $self->getter_ref;
    return sub {
        my $instance = shift;
        my ($code, @args) = (@curry, @_);
        my $hash = $instance->$get;
        return
            map { $code->(@$_, @args) }
            map { [$_, $hash->{ $_ }] }
            keys %$hash;
    };
}

sub _generate_each_value_delegation {
    my ($self, $meta, @curry) = @_;
    my $name = $self->name;
    my $get = $self->getter_ref;
    return sub {
        my $instance = shift;
        my ($code, @args) = (@curry, @_);
        my $hash = $instance->$get;
        my @vals = values %$hash;
        for my $value (@vals) {
            local $_ = $value;
            $code->($value, @args);
        }
        return 1;
    };
}

sub _generate_keys_delegation {
    my ($self, $meta) = @_;
    my $name = $self->name;
    my $get = $self->getter_ref;
    return sub {
        return keys %{ $_[0]->$get };
    };
}

sub _generate_values_delegation {
    my ($self, $meta) = @_;
    my $name = $self->name;
    my $get = $self->getter_ref;
    return sub {
        return values %{ $_[0]->$get };
    };
}

sub _generate_kv_delegation {
    my ($self, $meta) = @_;
    my $name = $self->name;
    my $get = $self->getter_ref;
    return sub {
        my $hash = $_[0]->$get;
        return map { [$_, $hash->{$_}] } keys %$hash;
    };
}

sub _generate_get_delegation {
    my ($self, $meta, @curry) = @_;
    my $name = $self->name;
    my $get = $self->getter_ref;
    return sub {
        my $instance = shift;
        my ($key) = (@curry, @_);
        return $instance->$get->{ $key };
    };
}

sub _generate_get_required_delegation {
    my ($self, $meta, @curry) = @_;
    my $name = $self->name;
    my $get = $self->getter_ref;
    return sub {
        my $instance = shift;
        my ($key) = (@curry, @_);
        my $hash = $instance->$get;
        croak qq{Unknown $name key '$key'}
            unless exists $hash->{ $key };
        return $hash->{ $key };
    };
}

sub _generate_get_all_delegation {
    my ($self, $meta, @curry) = @_;
    my $name = $self->name;
    my $get = $self->getter_ref;
    return sub {
        my $instance = shift;
        my $hash = $instance->$get;
        return map { $hash->{ $_ } } @curry, @_;
    };
}

sub _make_item_setter {
    my ($self) = @_;
    my $name = $self->name;
    my $get = $self->getter_ref;
    my $sig_insert = $self->_signal_name('insert');
    my $sig_change = $self->_signal_name('update');
    return sub {
        my ($instance, $key, $value) = @_;
        my $hash = $instance->$get;
        my $old = $hash->{ $key };
        my $has_old = exists $hash->{ $key };
        $hash->{ $key } = $value;
        if (defined $sig_change and $has_old) {
            $instance->signal_emit($sig_change, $key, $value, $old);
        }
        elsif (defined $sig_insert) {
            $instance->signal_emit($sig_insert, $key, $value);
        }
        return 1;
    };
}

sub _generate_get_buildable_delegation {
    my ($self, $meta, @curry) = @_;
    my $name = $self->name;
    my $get = $self->getter_ref;
    my $set = $self->_make_item_setter;
    my $coerce = $self->item_coercion;
    my $check = $self->item_constraint;
    return sub {
        my $instance = shift;
        my ($builder, $key, @args) = (@curry, @_);
        my $hash = $instance->$get;
        return $hash->{ $key }
            if exists $hash->{ $key };
        my $value = $instance->$builder($key);
        try {
            $value = $coerce->($value)
                if $coerce;
            $check->($value)
                if $check;
        }
        catch {
            my $err = $_;
            chomp $err;
            croak qq{Property '$name' item '$key' value error: $err};
        };
        $instance->$set($key, $value, @args);
        return $value;
    };
}

sub _generate_set_delegation {
    my ($self, $meta, @curry) = @_;
    my $name = $self->name;
    my $set = $self->_make_item_setter;
    my $coerce = $self->item_coercion;
    my $check = $self->item_constraint;
    return sub {
        my $instance = shift;
        my ($key, $value) = (@curry, @_);
        try {
            $value = $coerce->($value)
                if $coerce;
            $check->($value)
                if $check;
        }
        catch {
            my $err = $_;
            chomp $err;
            croak qq{Property '$name' item '$key' value error: $err};
        };
        $instance->$set($key, $value);
        return 1;
    };
}

sub _generate_set_all_delegation {
    my ($self, $meta, @curry) = @_;
    my $name = $self->name;
    my $set = $self->_make_item_setter;
    my $coerce = $self->item_coercion;
    my $check = $self->item_constraint;
    return sub {
        my $instance = shift;
        my %kv = (@curry, @_);
        my $last;
        try {
            my %clean = map {
                my $key = $last = $_;
                my $val = $kv{ $key };
                $val = $coerce->($val)
                    if $coerce;
                $check->($val)
                    if $check;
                ($key, $val);
            } keys %kv;
            %kv = %clean;
        }
        catch {
            my $err = $_;
            chomp $err;
            croak qq{Property '$name' item '$last' value error: $err};
        };
        for my $key (keys %kv) {
            $instance->$set($key, $kv{ $key });
        }
        return 1;
    };
}

sub _make_clearer {
    my ($self) = @_;
    my $name = $self->name;
    my $get = $self->getter_ref;
    my $sig_delete = $self->_signal_name('delete');
    return sub {
        my ($instance, $key) = @_;
        my $hash = $instance->$get;
        return undef
            unless exists $hash->{ $key };
        my $old = delete $hash->{ $key };
        if (defined $sig_delete) {
            $instance->signal_emit($sig_delete, $key, $old);
        }
        return $old;
    };
}

sub _generate_delete_delegation {
    my ($self, $meta, @curry) = @_;
    my $clear = $self->_make_clearer;
    return sub {
        my $instance = shift;
        my ($key) = (@curry, @_);
        return $instance->$clear($key);
    };
}

sub _generate_delete_all_delegation {
    my ($self, $meta, @curry) = @_;
    my $clear = $self->_make_clearer;
    return sub {
        my $instance = shift;
        return map {
            $instance->$clear($_);
        } @curry, @_;
    };
}

sub _generate_clear_delegation {
    my ($self, $meta) = @_;
    my $clear = $self->_make_clearer;
    my $get = $self->getter_ref;
    return sub {
        my $instance = shift;
        my $hash = $instance->$get;
        $instance->$clear($_)
            for keys %$hash;
        return 1;
    };
}

sub _generate_exists_delegation {
    my ($self, $meta, @curry) = @_;
    my $get = $self->getter_ref;
    return sub {
        my $instance = shift;
        my ($key) = (@curry, @_);
        return exists $instance->$get->{ $key };
    };
}

sub _generate_defined_delegation {
    my ($self, $meta, @curry) = @_;
    my $get = $self->getter_ref;
    return sub {
        my $instance = shift;
        my ($key) = (@curry, @_);
        return defined $instance->$get->{ $key };
    };
}

sub _generate_count_delegation {
    my ($self, $meta) = @_;
    my $get = $self->getter_ref;
    return sub {
        return scalar keys %{ $_[0]->$get };
    };
}

sub _generate_shallow_clone_delegation {
    my ($self, $meta) = @_;
    my $get = $self->getter_ref;
    return sub {
        return { %{ $_[0]->$get } };
    };
}

with qw(
    Object::Glib::Meta::Property::Typed::Container
);

1;
