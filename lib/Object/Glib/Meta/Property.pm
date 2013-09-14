use strictures 1;

package Object::Glib::Meta::Property;
use Moo;
use Glib;
use Carp qw( croak confess );
use Try::Tiny;
use Safe::Isa;
use Object::Glib::Types qw( :ident :ref );
use Object::Glib::Values qw( identify );
use Object::Glib::CarpGroup;

my $_mode_map;
use constant $_mode_map = {
    MODE_READ => 'ro',
    MODE_READP => 'rpo',
    MODE_READ_WRITE => 'rw',
    MODE_READP_WRITEP => 'rpwp',
    MODE_READ_WRITEP => 'rwp',
    MODE_BARE => 'bare',
    MODE_LAZY => 'lazy',
};
my %_allowed_mode = reverse %$_mode_map;

use namespace::clean;

has name => (is => 'ro', required => 1, isa => \&isa_ident);
has setter_ref => (is => 'ro', lazy => 1, builder => 1, init_arg => undef);
has getter_ref => (is => 'ro', lazy => 1, builder => 1, init_arg => undef);
has init_ref => (is => 'ro', lazy => 1, builder => 1, init_arg => undef);
has pspec => (is => 'lazy', init_arg => undef);

has required => (is => 'ro');
has clearer => (is => 'ro', isa => \&isa_auto_ident);
has predicate => (is => 'ro', isa => \&isa_auto_ident);

has property_signals => (
    is => 'bare',
    lazy => 1,
    reader => '_property_signals',
    init_arg => undef,
    builder => sub { [] },
);

has default => (
    is => 'ro',
    isa => \&maybe_code,
    lazy => 1,
    builder => sub { undef },
);

has constraint => (
    is => 'ro',
    isa => \&maybe_code,
    lazy => 1,
    init_arg => 'isa',
    builder => sub { undef },
);

has coercion => (
    is => 'ro',
    isa => \&maybe_code,
    lazy => 1,
    init_arg => 'coerce',
    builder => sub { undef },
);

my %_mode_readable = map { ($_, 1) } (
    MODE_READ, MODE_READ_WRITE, MODE_READ_WRITEP,
);

has readable => (
    is => 'ro',
    lazy => 1,
    builder => sub { $_mode_readable{ $_[0]->mode } ? 1 : 0 },
);

my %_mode_writable = map { ($_, 1) } (
    MODE_READ_WRITE,
);

has writable => (
    is => 'ro',
    lazy => 1,
    builder => sub { $_mode_writable{ $_[0]->mode } ? 1 : 0 },
);

has lazy => (
    is => 'ro',
    lazy => 1,
    builder => sub { $_[0]->mode eq MODE_LAZY ? 1 : 0 },
);

has mode => (
    is => 'ro',
    isa => sub {
        die sprintf "Expected one of %s, received %s\n",
            join(', ', keys %_allowed_mode),
            identify($_[0])
            unless defined $_[0] and $_allowed_mode{ $_[0] };
    },
    default => sub { MODE_BARE },
    init_arg => 'is',
);

my %_reader_format = (
    (map { ($_, 'get_%s') }
        MODE_READ,
        MODE_READ_WRITE,
        MODE_READ_WRITEP,
    ),
    (map { ($_, '_get_%s') }
        MODE_READP,
        MODE_READP_WRITEP,
    ),
);

has reader => (
    is => 'ro',
    isa => \&maybe_ident,
    lazy => 1,
    builder => sub {
        my ($self) = @_;
        my $mode = $self->mode;
        return sprintf $_reader_format{ $mode }, $self->name
            if exists $_reader_format{ $mode };
        return undef;
    },
);

my %_writer_format = (
    (map { ($_, 'set_%s') }
        MODE_READ_WRITE,
    ),
    (map { ($_, '_set_%s') }
        MODE_READ_WRITEP,
        MODE_READP_WRITEP,
    ),
);

has writer => (
    is => 'ro',
    isa => \&maybe_ident,
    lazy => 1,
    builder => sub {
        my ($self) = @_;
        my $mode = $self->mode;
        return sprintf $_writer_format{ $mode }, $self->name
            if exists $_writer_format{ $mode };
        return undef;
    },
);

has init_arg => (
    is => 'ro',
    isa => \&maybe_ident,
    lazy => 1,
    builder => sub { $_[0]->name },
);

has builder => (
    is => 'ro',
    isa => \&maybe_code_ident,
    lazy => 1,
    builder => sub {
        return 1 if $_[0]->lazy and not $_[0]->default;
        return undef;
    },
);

has trigger_set => (
    is => 'ro',
    isa => \&isa_auto_ident,
    init_arg => 'on_set',
);

has trigger_unset => (
    is => 'ro',
    isa => \&isa_auto_ident,
    init_arg => 'on_unset',
);

sub _check_property_signals { 1 }
sub _builder_real { $_[0]->_autom($_[0]->builder, '_build_%s', 1) }
sub property_signals { @{ $_[0]->_property_signals } }

sub BUILD {
    my ($self) = @_;
    croak q{A defaulted property cannot be required}
        if $self->required and defined $self->default;
    croak q{A required property needs an init_arg}
        if $self->required and not defined $self->init_arg;
    croak q{A property cannot have a default and a builder}
        if defined $self->builder and defined $self->default;
    croak q{A lazy property needs a builder or default}
        if $self->lazy and not(
            defined $self->builder or defined $self->default
        );
    $self->_check_property_signals;
}

sub install_into {
    my ($self, $meta) = @_;
    $self->_install_accessors_into($meta);
    $self->_install_clearer_into($meta);
    $self->_install_builder_into($meta);
    $self->_install_predicate_into($meta);
    return 1;
}

sub _install_predicate_into {
    my ($self, $meta) = @_;
    if (defined( my $pred = $self->predicate )) {
        $pred = $self->_autom($pred, '_has_%s');
        my $name = $self->name;
        $meta->install_method($pred, sub {
            my ($instance) = @_;
            return $instance->{ $name } ? 1 : 0;
        });
    }
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
            croak qq{Property '$name' value error: $err};
        };
        return 1;
    };
}

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
    my $check = $self->constraint;
    return sub {
        my ($instance) = @_;
        my $value = $instance->$get;
        try {
            $check->($value)
                if $check;
        }
        catch {
            my $err = $_;
            chomp $err;
            croak join ' ',
                qq{Property '$name' construction initialisation},
                qq{error: $err};
        };
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
    if ($lazy) {
        my $get = defined($builder) ? $builder : $default;
        my $set = $self->_autom($self->trigger_set, '_on_%s_set');
        my $on_set = defined $set;
        my $pspec = $self->pspec;
        my $check = $self->constraint;
        return sub {
            my ($instance) = @_;
            if ($instance->{ $name }) {
                return ${ $instance->{ $name } };
            }
            my $value = $instance->$get;
            try {
                $check->($value)
                    if $check;
            }
            catch {
                my $err = $_;
                chomp $err;
                croak join ' ',
                    qq{Property '$name' lazy initialisation},
                    qq{error: $err};
            };
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
