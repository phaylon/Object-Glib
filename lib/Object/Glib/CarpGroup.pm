use strictures 1;

package Object::Glib::CarpGroup;

use namespace::clean;

my @_external = qw(
    Try::Tiny
);

my @_internal = 'Object::Glib', map "Object::Glib::$_", qw(
    Meta::Class
    Meta::Property
    Meta::Property::Type::Array
    Meta::Property::Type::Hash
    Meta::Property::Type::Object
    Meta::Property::Typed
    Meta::Property::Typed::Container
    Meta::Property::Typed::Primitive
    Meta::Signal
    Registry
    Types
    Values
);

sub import {
    my $package = caller;
    my $ignore = do {
        no strict 'refs';
        no warnings 'once';
        \@{ "${package}::CARP_NOT" };
    };
    push @$ignore, @_internal, @_external;
}

1;
