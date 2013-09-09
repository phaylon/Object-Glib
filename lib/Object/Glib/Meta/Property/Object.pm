use strictures 1;

package Object::Glib::Meta::Property::Object;
use Moo;
use Safe::Isa;
use Scalar::Util qw( blessed );
use Object::Glib::Types qw( :oo );

use namespace::clean;

extends 'Object::Glib::Meta::Property';

has class_constraint => (
    is => 'ro',
    isa => \&maybe_class,
    init_arg => 'class',
    builder => sub { undef },
);

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
