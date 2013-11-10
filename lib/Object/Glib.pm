use strictures 1;

package Object::Glib;
use parent 'Object::Glib::Exporter::Common';
use Carp qw( croak );
use Class::Method::Modifiers ();
use Import::Into;
use Object::Glib::CarpGroup;
use Object::Glib::Exporter;

use aliased 'Object::Glib::Meta::Class';

use namespace::clean;

our $VERSION = '0.000001';
$VERSION = eval $VERSION;

setup_exports(
    meta_class => Class,
    export => [qw(
        property
        signal
        extends
        with
        register
    )],
    finalize => sub {
        my ($package) = @_;
        Class::Method::Modifiers->import::into($package);
        strictures->import::into($package, 1);
        return 1;
    },
);

sub _proto_extends {
    my ($meta, $super) = @_;
    croak q{Missing superclass definition}
        unless defined $super;
    $meta->set_superclass($super);
    return 1;
}

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
