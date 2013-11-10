use strictures 1;

package Object::Glib::Meta::Class;
use Moo;
use Glib;
use Module::Runtime qw( use_module );
use Carp qw( croak );
use Sub::Install qw( install_sub );
use Object::Glib::Registry qw( has_meta find_meta );
use Object::Glib::Types qw( :oo );
use Class::ISA;
use Object::Glib::CarpGroup;
use Object::Glib::Packages qw( deparse_package );
use Role::Tiny ();
use Package::Stash;

use namespace::clean;

has package => (
    is => 'ro',
    required => 1,
);

has superclass => (
    is => 'ro',
    init_arg => undef,
    writer => '_set_raw_superclass',
);

has interfaces => (
    is => 'bare',
    reader => '_interfaces',
    default => sub { [] },
    init_arg => undef,
);

sub BUILD {
    my ($self) = @_;
    $self->set_superclass('Glib::Object');
}

sub interfaces { @{ $_[0]->_interfaces } }

sub _hierarchy {
    my ($self) = @_;
    return(
        $self->package,
        Glib::Type->list_ancestors($self->superclass),
    );
    #return Class::ISA::self_and_super_path($self->package);
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

sub install_related {
    my ($self, $related) = @_;
    $related->install_into($self);
    return 1;
}

sub set_superclass {
    my ($self, $super) = @_;
    $super = deparse_package($super, 'superclass');
    $self->_set_raw_superclass($super);
    do {
        my $package = $self->package;
        no strict 'refs';
        @{ "${package}::ISA" } = ($super);
    };
    return 1;
}

sub add_role {
    my ($self, $role) = @_;
    $role = deparse_package($role, 'role');
    my @glib_super = eval { Glib::Type->list_ancestors($role) };
    if (grep { $_ eq 'Glib::Interface' } @glib_super) {
        push @{ $self->_interfaces }, $role;
    }
    elsif (has_meta $role) {
        my $meta = find_meta($role);
        $meta->apply_to($self);
    }
    elsif (Role::Tiny->is_role($role)) {
        Role::Tiny->apply_roles_to_package($self->package);
    }
    else {
        croak "Unable to apply role $role";
    }
    return 1;
}

sub register {
    my ($self) = @_;
    do {
        my $package = $self->package;
        no strict 'refs';
        @{ "${package}::ISA" } = ();
    };
    Glib::Type->register_object(
        $self->superclass,
        $self->package,
        interfaces => [$self->interfaces],
        signals => {
            (map { ($_->name, $_->glib) } $self->signals),
        },
        properties => [
            (map { $_->glib } $self->properties),
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
        my $stash = Package::Stash->new($class);
        if (my $code = $stash->get_symbol('&BUILD_INSTANCE')) {
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
            $instance->set_property(object_glib_state => 'constructed');
            $instance->set_property(%direct);
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
            $instance->set_property(object_glib_state => 'done');
            return $instance;
        },
    };
}

with qw(
    Object::Glib::Meta::HasProperties
    Object::Glib::Meta::HasSignals
);

1;
