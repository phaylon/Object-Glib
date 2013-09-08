use strictures 1;

package Object::Glib::Meta::Property;
use Moo;
use Glib;
use Carp qw( croak );
use Try::Tiny;

use constant {
    MODE_READ => 'ro',
    MODE_READP => 'rpo',
    MODE_READ_WRITE => 'rw',
    MODE_READP_WRITEP => 'rpwp',
    MODE_READ_WRITEP => 'rwp',
    MODE_BARE => 'bare',
    MODE_LAZY => 'lazy',
};

use namespace::clean;

our @CARP_NOT = qw(
    Object::Glib
    Object::Glib::Meta::Class
);

has name => (is => 'ro', required => 1);
has setter_ref => (is => 'ro', lazy => 1, builder => 1, init_arg => undef);
has getter_ref => (is => 'ro', lazy => 1, builder => 1, init_arg => undef);
has init_ref => (is => 'ro', lazy => 1, builder => 1, init_arg => undef);
has pspec => (is => 'lazy', init_arg => undef);

has mode => (is => 'ro', default => sub { MODE_BARE }, init_arg => 'is');
has writable => (is => 'ro', lazy => 1, builder => 1);
has readable => (is => 'ro', lazy => 1, builder => 1);
has reader => (is => 'ro', lazy => 1, builder => 1);
has writer => (is => 'ro', lazy => 1, builder => 1);
has init_arg => (is => 'ro', lazy => 1, builder => 1);
has lazy => (is => 'ro', lazy => 1, builder => 1);
has builder => (is => 'ro', lazy => 1, builder => 1);
has default => (is => 'ro', lazy => 1);
has constraint => (is => 'ro', init_arg => 'isa');
has coercion => (is => 'ro', init_arg => 'coerce');
has clearer => (is => 'ro');
has trigger_set => (is => 'ro', init_arg => 'on_set');
has trigger_unset => (is => 'ro', init_arg => 'on_unset');

sub install_into {
    my ($self, $meta) = @_;
    $self->_install_accessors_into($meta);
    $self->_install_clearer_into($meta);
    $self->_install_builder_into($meta);
    return 1;
}

sub _install_clearer_into {
    my ($self, $meta) = @_;
    if (defined( my $clearer = $self->clearer )) {
        $clearer = $self->_autom($clearer, '_clear_%s');
        my $unset = $self->_autom($self->trigger_unset, '_on_%s_unset');
        my $on_unset = defined $unset;
        my $name = $self->name;
        my $pspec = $self->pspec;
        $meta->install_method($clearer, sub {
            my ($instance) = @_;
            if ($on_unset and $instance->{ $name }) {
                $instance->$unset(${ $instance->{ $name } });
            }
            $instance->{ $name } = undef;
            $instance->signal_emit("notify::$name", $pspec);
            return 1;
        });
    }
    return 1;
}

sub _install_builder_into {
    my ($self, $meta) = @_;
    if (ref( my $builder = $self->builder ) eq 'CODE') {
        my $name = $self->name;
        $meta->install_method("_build_$name", $builder);
    }
    return 1;
}

sub _install_accessors_into {
    my ($self, $meta) = @_;
    if (defined( my $reader = $self->reader )) {
        $meta->install_method($reader, $self->getter_ref);
    }
    if (defined( my $writer = $self->writer )) {
        $meta->install_method($writer, $self->setter_ref);
    }
    return 1;
}

sub default_on_build {
    my ($self) = @_;
    return 0
        if $self->lazy
        or not(defined $self->builder or defined $self->default);
    return 1;
}

sub _autom {
    my ($self, $value, $format, $allow_code) = @_;
    return undef
        unless defined $value;
    return sprintf($format, $self->name)
        if $value eq 1
        or ($allow_code and ref($value) eq 'CODE');
    return $value;
}

sub _build_lazy {
    my ($self) = @_;
    return 1
        if $self->mode eq MODE_LAZY;
    return 0;
}

sub _build_builder {
    my ($self) = @_;
    return 1
        if $self->lazy and not $self->default;
    return undef;
}

sub _build_init_arg {
    my ($self) = @_;
    return $self->name;
}

sub _build_setter_ref {
    my ($self) = @_;
    my $name = $self->name;
    my $coerce = $self->coercion;
    my $check = $self->constraint;
    my $pspec = $self->pspec;
    my $set = $self->_autom($self->trigger_set, '_on_%s_set');
    my $on_set = defined $set;
    my $unset = $self->_autom($self->trigger_unset, '_on_%s_unset');
    my $on_unset = defined $unset;
    return sub {
        my ($instance, $value) = @_;
        return 1
            unless $instance->get('object_glib_state');
        try {
            $value = $coerce->($value)
                if $coerce;
            $check->($value)
                if $check;
            if ($on_unset and $instance->{ $name }) {
                $instance->$unset(${ $instance->{ $name } });
            }
            $instance->{ $name } = \$value;
            if ($on_set) {
                $instance->$set(${ $instance->{ $name } });
            }
            $instance->signal_emit("notify::$name", $pspec);
        }
        catch {
            my $err = $_;
            chomp $err;
            croak qq{Property '$name' initialisation error: $err};
        };
        return 1;
    };
}

sub _builder_real { $_[0]->_autom($_[0]->builder, '_build_%s', 1) }

sub _build_init_ref {
    my ($self) = @_;
    my $name = $self->name;
    my $lazy = $self->lazy;
    my $builder = $self->_builder_real;
    my $default = $self->default;
    my $get = defined($builder) ? $builder : $default;
    return sub { 0 }
        if $lazy or not defined($get);
    my $set = $self->_autom($self->trigger_set, '_on_%s_set');
    my $on_set = defined $set;
    return sub {
        my ($instance) = @_;
        my $value = $instance->$get;
        $instance->{ $name } = \$value;
        if ($on_set) {
            $instance->$set(${ $instance->{ $name } });
        }
        return ${ $instance->{ $name } };
    };
}

sub _build_getter_ref {
    my ($self) = @_;
    my $name = $self->name;
    my $lazy = $self->lazy;
    my $builder = $self->_builder_real;
    my $default = $self->default;
    croak qq{Property '$name' cannot have default and builder}
        if defined $builder and defined $default;
    if ($lazy) {
        croak qq{Property '$name' is lazy but has no builder or default}
            unless defined $builder or defined $default;
        my $get = defined($builder) ? $builder : $default;
        my $set = $self->_autom($self->trigger_set, '_on_%s_set');
        my $on_set = defined $set;
        my $pspec = $self->pspec;
        return sub {
            my ($instance) = @_;
            if ($instance->{$name}) {
                return ${ $instance->{ $name } };
            }
            my $value = $instance->$get;
            $instance->{ $name } = \$value;
            if ($on_set) {
                $instance->$set(${ $instance->{ $name } });
            }
            $instance->signal_emit("notify::$name", $pspec);
            return $value;
        };
    }
    else {
        return sub {
            my ($instance) = @_;
            if ($instance->{$name}) {
                return ${ $instance->{ $name } };
            }
            return undef;
        };
    }
}

sub _build_reader {
    my ($self) = @_;
    my $name = $self->name;
    my $mode = $self->mode;
    return "get_$name"
        if $mode eq MODE_READ
        or $mode eq MODE_READ_WRITE
        or $mode eq MODE_READ_WRITEP;
    return "_get_$name"
        if $mode eq MODE_READP
        or $mode eq MODE_READP_WRITEP;
    return undef;
}

sub _build_writer {
    my ($self) = @_;
    my $name = $self->name;
    my $mode = $self->mode;
    return "set_$name"
        if $mode eq MODE_READ_WRITE;
    return "_set_$name"
        if $mode eq MODE_READ_WRITEP
        or $mode eq MODE_READP_WRITEP;
    return undef;
}

my %_mode_readable = map { ($_, 1) } (
    MODE_READ, MODE_READ_WRITE, MODE_READ_WRITEP,
);

my %_mode_writable = map { ($_, 1) } (
    MODE_READ_WRITE,
);

sub _build_readable {
    my ($self) = @_;
    return $_mode_readable{ $self->mode };
}

sub _build_writable {
    my ($self) = @_;
    return $_mode_writable{ $self->mode };
}

sub _build_pspec {
    my ($self) = @_;
    my @flags = (
        defined($self->init_arg) ? 'construct' : (),
        'readable',
        'writable',
    );
    return Glib::ParamSpec->scalar(
        $self->name,
        $self->name,
        '',
        [@flags],
    );
}

sub glib {
    my ($self) = @_;
    my $name = $self->name;
    return {
        pspec => $self->pspec,
        $self->readable ? (
            get => $self->getter_ref,
        ) : (
            get => sub {
                croak qq{Property '$name' cannot be read directly}
                    if $_[0]->get('object_glib_state');
            },
        ),
        $self->writable ? (
            set => $self->setter_ref,
        ) : (
            set => sub {
                croak qq{Property '$name' cannot be written directly}
                    if $_[0]->get('object_glib_state');
            },
        ),
    };
}

1;
