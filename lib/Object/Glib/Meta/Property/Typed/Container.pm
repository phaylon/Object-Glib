use strictures 1;

package Object::Glib::Meta::Property::Typed::Container;
use Safe::Isa;
use Object::Glib::Types qw( :ref :oo );
use Object::Glib::CarpGroup;
use Moo::Role;

use namespace::clean;

has item_constraint => (
    is => 'ro',
    lazy => 1,
    isa => \&maybe_code,
    init_arg => 'item_isa',
    builder => sub {
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
    },
);

has item_coercion => (
    is => 'ro',
    isa => \&isa_code,
    init_arg => 'item_coerce',
);

has item_class_constraint => (
    is => 'ro',
    isa => \&isa_class,
    init_arg => 'item_class',
);

with qw(
    Object::Glib::Meta::Property::Typed::Primitive
);

1;
