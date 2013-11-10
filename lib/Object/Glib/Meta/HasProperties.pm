use strictures 1;

package Object::Glib::Meta::HasProperties;
use Object::Glib::Registry qw( has_meta find_meta );
use Object::Glib::CarpGroup;
use Moo::Role;

use namespace::clean;

requires qw(
    install_related
);

has properties => (
    is => 'bare',
    init_arg => undef,
    default => sub { {} },
    reader => '_properties',
);

sub add_property {
    my ($self, $property) = @_;
    $self->_properties->{ $property->name } = $property;
    $self->install_related($property);
    return 1;
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
    my @nonmeta = grep {
        not(has_meta($_))
        #and $_->isa('Glib::Object')
    } $self->_hierarchy;
    return $nonmeta[0]->list_properties;
}

1;
