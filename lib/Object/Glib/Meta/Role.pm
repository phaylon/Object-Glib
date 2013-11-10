use strictures 1;

package Object::Glib::Meta::Role;
use Moo;
use Role::Tiny ();

use namespace::clean;

has package => (
    is => 'ro',
    required => 1,
);

has applications => (
    is => 'bare',
    reader => '_applications',
    init_arg => undef,
    default => sub { [] },
);

sub install_related { }

sub add_property {
    my ($self, $property) = @_;
    push @{ $self->_applications }, [add_property => $property];
    return 1;
}

sub add_signal {
    my ($self, $signal) = @_;
    push @{ $self->_applications }, [add_signal => $signal];
    return 1;
}

sub add_role {
    my ($self, $role) = @_;
    push @{ $self->_applications }, [add_role => $role];
    return 1;
}

sub apply_to {
    my ($self, $target) = @_;
    Role::Tiny->apply_roles_to_package($target->package, $self->package);
    for my $application (@{ $self->_applications }) {
        my ($method, @args) = @$application;
        $target->$method(@args);
    }
    return 1;
}

1;
