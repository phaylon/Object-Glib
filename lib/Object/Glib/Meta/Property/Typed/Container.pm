use strictures 1;

package Object::Glib::Meta::Property::Typed::Container;
use Safe::Isa;
use Moo::Role;

use namespace::clean;

has item_constraint => (is => 'lazy', init_arg => 'item_isa');
has item_coercion => (is => 'ro', init_arg => 'item_coerce');
has item_class_constraint => (is => 'ro', init_arg => 'item_class');

sub _build_item_constraint {
    my ($self) = @_;
    if (defined( my $class = $self->item_class_constraint )) {
        return sub {
            my $val = $_[0];
            die "Not an instance of $class\n"
                unless $val->$_isa($class);
            return 1;
        };
    }
    return undef;
}

with qw(
    Object::Glib::Meta::Property::Typed::Primitive
);

1;
