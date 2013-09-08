use strictures 1;

package Object::Glib::Meta::Class;
use Moo;
use Glib;
use Module::Runtime qw( use_module );
use Carp qw( croak );
use Sub::Install qw( install_sub );
use Object::Glib::Registry qw( has_meta find_meta );
use Class::ISA;

use namespace::clean;

our @CARP_NOT = qw(
    Object::Glib
);

has package => (
    is => 'ro',
    required => 1,
);

has signals => (
    is => 'bare',
    init_arg => undef,
    default => sub { {} },
    reader => '_signals',
);

has properties => (
    is => 'bare',
    init_arg => undef,
    default => sub { {} },
    reader => '_properties',
);

has superclass => (
    is => 'ro',
    init_arg => undef,
    writer => '_set_raw_superclass',
);

sub BUILD {
    my ($self) = @_;
    $self->set_superclass('Glib::Object');
}

sub _hierarchy {
    my ($self) = @_;
    return Class::ISA::self_and_super_path($self->package);
}

sub install_method {
    my ($self, $name, $code) = @_;
    install_sub {
        into => $self->package,
        as => $name,
        code => $code,
    };
    return 1;
}

sub add_property {
    my ($self, $property) = @_;
    $self->_properties->{ $property->name } = $property;
    $property->install_into($self);
    return 1;
}

sub add_signal {
    my ($self, $signal) = @_;
    $self->_signals->{ $signal->name } = $signal;
    $signal->install_into($self);
    return 1;
}

sub set_superclass {
    my ($self, $super) = @_;
    if (ref($super) eq 'ARRAY') {
        croak q{An inner package specification needs a module and class}
            unless @$super == 2;
        my ($module, $class) = @$super;
        $super = join '::', $module, $class;
        use_module($module)
            unless $super->can('new');
        $module->init
            if $module->can('init');
    }
    else {
        use_module($super)
            unless $super->can('new');
    }
    $self->_set_raw_superclass($super);
    do {
        my $package = $self->package;
        no strict 'refs';
        @{ "${package}::ISA" } = ($super);
    };
    return 1;
}

sub register {
    my ($self) = @_;
    Glib::Type->register_object(
        $self->superclass,
        $self->package,
        signals => {
            (map { ($_->name, $_->glib) } $self->signals),
        },
        properties => [
            (map { $_->glib } values %{ $self->_properties }),
            Glib::ParamSpec->scalar(
                'object_glib_state',
                'object_glib_state',
                '',
                [qw( readable writable construct )],
            ),
        ],
    );
    $self->_install_constructor;
    return 1;
}

sub signals {
    my ($self) = @_;
    return(
        (values %{ $self->_signals }),
        (map { ($_->property_signals) } $self->properties),
    );
}

sub properties {
    my ($self) = @_;
    return values %{ $self->_properties };
}

sub _meta_properties {
    my ($self) = @_;
    return map {
        my $class = $_;
        has_meta($class)
            ? (find_meta($class)->properties)
            : ();
    } $self->_hierarchy;
}

sub _nonmeta_properties {
    my ($self) = @_;
    my @nonmeta = grep { not has_meta($_) } $self->_hierarchy;
    return $nonmeta[0]->list_properties;
}

sub _prepare_build_spec {
    my ($self) = @_;
    my %spec = (builders => []);
    for my $prop ($self->_meta_properties) {
        if (defined( my $init_arg = $prop->init_arg )) {
            $spec{set}{ $init_arg } = $prop->setter_ref;
        }
        if ($prop->default_on_build) {
            if (defined( my $init_arg = $prop->init_arg )) {
                $spec{default}{ $init_arg } = $prop->init_ref;
            }
            else {
                $spec{default_always}{ $prop->name } = $prop->init_ref;
            }
        }
        if ($prop->required) {
            $spec{required}{ $prop->init_arg } = 1;
        }
    }
    for my $prop ($self->_nonmeta_properties) {
        my $flags = $prop->get_flags;
        if ($flags >= ['construct'] or $flags >= ['construct-only']) {
            $spec{raw}{construct}{ $prop->get_name } = 1;
        }
        elsif ($flags >= ['writable']) {
            $spec{raw}{set}{ $prop->get_name } = 1;
        }
    }
    for my $class (reverse $self->_hierarchy) {
        if (my $code = $class->can('BUILD_INSTANCE')) {
            push @{ $spec{builders} }, $code;
        }
    }
    return \%spec;
}

sub _install_constructor {
    my ($self) = @_;
    my $spec = $self->_prepare_build_spec;
    install_sub {
        into => $self->package,
        as => 'new',
        code => sub {
            my ($class, %arg) = @_;
            my %orig = %arg;
            my (%construct, %direct, %setter);
            for my $key (keys %arg) {
                if ($spec->{raw}{construct}{ $key }) {
                    $construct{ $key } = delete $arg{ $key };
                }
                elsif ($spec->{raw}{set}{ $key }) {
                    $direct{ $key } = delete $arg{ $key };
                }
                elsif (my $code = $spec->{set}{ $key }) {
                    $setter{ $key } = [$code, delete $arg{ $key }];
                }
            }
            my @missing =
                sort
                grep { not exists $orig{ $_ } }
                keys %{ $spec->{required} };
            croak sprintf q{Missing constructor arguments for %s: %s},
                $class, join ', ', @missing
                if @missing;
            my $instance = Glib::Object::new($class, %construct);
            $instance->set(object_glib_state => 'constructed');
            $instance->set(%direct);
            for my $key (keys %setter) {
                my ($code, $value) = @{ $setter{ $key } };
                $instance->$code($value);
            }
            for my $key (keys %{ $spec->{default_always} }) {
                my $code = $spec->{default_always}{ $key };
                $instance->$code;
            }
            for my $key (keys %{ $spec->{default} }) {
                next if exists $orig{ $key };
                my $code = $spec->{default}{ $key };
                $instance->$code;
            }
            for my $builder (@{ $spec->{builders} }) {
                $instance->$builder(\%orig);
            }
            my @unknown = grep { exists $orig{$_} } sort keys %arg;
            croak sprintf qq{Unknown constructor arguments for %s: %s},
                $class, join ', ', @unknown
                if @unknown;
            $instance->set(object_glib_state => 'done');
            return $instance;
        },
    };
}

1;
