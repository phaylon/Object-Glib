use strictures 1;

package Object::Glib;
use Carp qw( croak );
use Sub::Install qw( install_sub );
use Object::Glib::Registry qw( find_meta register_meta );
use Class::Method::Modifiers ();
use Import::Into;
use Module::Runtime qw( use_module );

use aliased 'Object::Glib::Meta::Class';
use aliased 'Object::Glib::Meta::Property';
use aliased 'Object::Glib::Meta::Signal';

use namespace::clean;

our $VERSION = '0.000001';
$VERSION = eval $VERSION;

my @_export = qw(
    property
    signal
    extends
    implements
    register
);

sub import {
    my $class = caller;
    my $meta = Class->new(package => $class);
    register_meta($meta);
    for my $sub (@_export) {
        my $code = __PACKAGE__->can("_proto_$sub");
        install_sub {
            into => $class,
            as => $sub,
            code => sub { $code->($meta, @_) },
        };
    }
    Class::Method::Modifiers->import::into($class);
    strictures->import::into($class, 1);
    return 1;
}

sub _proto_property {
    my $meta = shift;
    my $name = shift;
    croak q{Missing property name}
        unless defined $name;
    croak q{Expected property name followed by key/value list}
        if @_ % 2;
    my %arg = @_;
    my $prop_class;
    if (my $type = delete $arg{type}) {
        $prop_class = use_module(join '::', Property, $type);
    }
    else {
        $prop_class = Property;
    }
    my $prop = $prop_class->new(%arg, name => $name);
    $meta->add_property($prop);
    return 1;
}

sub _proto_extends {
    my ($meta, $super) = @_;
    croak q{Missing superclass definition}
        unless defined $super;
    $meta->set_superclass($super);
    return 1;
}

sub _proto_signal {
    my $meta = shift;
    my $name = shift;
    croak q{Missing signal name}
        unless defined $name;
    croak q{Expected signal name followed by key/value list}
        if @_ % 2;
    my %arg = @_;
    my $signal = Signal->new(%arg, name => $name);
    $meta->add_signal($signal);
    return 1;
}

sub _proto_implements { }

sub _proto_register {
    my $meta = shift;
    $meta->register;
    return 1;
}

1;

=head1 NAME

Object::Glib - Description goes here

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

 Robert Sedlacek <rs@474.at>

=head1 CONTRIBUTORS

None yet - maybe this software is perfect! (ahahahahahahahahaha)

=head1 COPYRIGHT

Copyright (c) 2013 the Object::Glib L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.
