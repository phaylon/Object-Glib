use strictures 1;

package Object::Glib::Registry;
use Carp qw( croak );

use namespace::clean;
use Exporter 'import';

our @EXPORT_OK = qw(
    register_meta
    has_meta
    find_meta
);

our @CARP_NOT = qw(
    Object::Glib
    Object::Glib::Meta::Class
);

my %_registry;

sub find_meta {
    my ($class) = @_;
    my $meta = $_registry{ $class }
        or croak qq{Object::Glib was not imported into $class};
    return $meta;
}

sub has_meta {
    my ($class) = @_;
    return $_registry{ $class } ? 1 : 0;
}

sub register_meta {
    my ($meta) = @_;
    my $class = $meta->package;
    croak qq{Object::Glib is already imported into $class}
        if $_registry{ $class };
    $_registry{ $class } = $meta;
    return 1;
}

1;
