use strictures 1;

package Object::Glib::Meta::HasSignals;
use Moo::Role;

use namespace::clean;

requires qw(
    install_related
);

has signals => (
    is => 'bare',
    init_arg => undef,
    default => sub { {} },
    reader => '_signals',
);

sub add_signal {
    my ($self, $signal) = @_;
    $self->_signals->{ $signal->name } = $signal;
    $self->install_related($signal);
    return 1;
}

sub signals {
    my ($self) = @_;
    return(
        (values %{ $self->_signals }),
        (map { ($_->property_signals) } $self->properties),
    );
}

1;
