use strictures 1;

package Object::Glib::Meta::Property::Type::Code;
use Moo;
use Object::Glib::CarpGroup;

use namespace::clean;

extends 'Object::Glib::Meta::Property';

sub _build_typed_builder { undef }
sub _build_signal_formats { {} }

sub _build_constraint {
    my ($self) = @_;
    return sub {
        my ($value) = @_;
        die "Not a code reference\n"
            unless ref $value eq 'CODE';
        return 1;
    };
}

sub _generate_execute_delegation {
    my ($self, $meta, @curry) = @_;
    my $get = $self->getter_ref;
    return sub {
        return $_[0]->$get->(@curry, @_[1 .. $#_]);
    };
}

with qw(
    Object::Glib::Meta::Property::Typed::Container
);

1;
