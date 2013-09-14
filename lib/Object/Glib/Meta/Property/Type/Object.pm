use strictures 1;

package Object::Glib::Meta::Property::Type::Object;
use Moo;
use Safe::Isa;
use Scalar::Util qw( blessed );
use Object::Glib::Types qw( :oo );
use Carp qw( croak confess );
use Object::Glib::CarpGroup;

use namespace::clean;

extends 'Object::Glib::Meta::Property';

has class_constraint => (
    is => 'ro',
    isa => \&maybe_class,
    init_arg => 'class',
    builder => sub { undef },
);

has role_constraint => (
    is => 'ro',
    isa => \&maybe_class,
    init_arg => 'does',
    builder => sub { undef },
);

sub BUILD {
    my ($self) = @_;
    croak qq{Cannot have a class and role constraint at the same time}
        if defined $self->class_constraint
        and defined $self->role_constraint;
}

sub _build_signal_formats { {} }
sub _build_typed_builder { undef }

sub _build_constraint {
    my ($self) = @_;
    if (defined( my $class = $self->class_constraint )) {
        return sub {
            my $val = $_[0];
            die "Not an instance of $class\n"
                unless $val->$_isa($class);
            return 1;
        };
    }
    elsif (defined( my $role = $self->role_constraint )) {
        return sub {
            my $val = $_[0];
            die "Does not implement $role\n"
                unless blessed($val) and (
                    ($val->can('DOES') and $val->DOES($role))
                    or
                    ($val->can('does') and $val->does($role))
                );
            return 1;
        };
    }
    return sub {
        my $val = $_[0];
        die "Not an object\n"
            unless blessed $val;
        return 1;
    };
}

sub _install_delegation_method {
    my ($self, $meta, $as, $target, @curry) = @_;
    my $get = $self->getter_ref;
    $meta->install_method($as, sub {
        my ($instance, @args) = @_;
        return $instance->$get->$target(@curry, @args);
    });
    return 1;
}

with qw(
    Object::Glib::Meta::Property::Typed
);

1;
