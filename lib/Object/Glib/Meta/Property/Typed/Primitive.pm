use strictures 1;

package Object::Glib::Meta::Property::Typed::Primitive;
use Carp qw( croak );
use Object::Glib::CarpGroup;
use Moo::Role;

use namespace::clean;

sub _install_delegation_method {
    my ($self, $meta, $as, $target, @curry) = @_;
    my $method = "_generate_${target}_delegation";
    croak qq{Unknown delegate method '$target'}
        unless $self->can($method);
    my $code = $self->$method($meta, @curry);
    $meta->install_method($as, $code);
    return 1;
}

with qw(
    Object::Glib::Meta::Property::Typed
);

1;
