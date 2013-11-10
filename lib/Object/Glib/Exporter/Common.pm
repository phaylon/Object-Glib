use strictures 1;

package Object::Glib::Exporter::Common;
use Module::Runtime qw( use_module );
use Object::Glib::CarpGroup;
use Carp qw( croak );

use aliased 'Object::Glib::Meta::Property';
use aliased 'Object::Glib::Meta::Signal';

use namespace::clean;

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
        $prop_class = use_module(join '::', Property, 'Type', $type);
    }
    else {
        $prop_class = Property;
    }
    my $prop = $prop_class->new(%arg, name => $name);
    $meta->add_property($prop);
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

sub _proto_with {
    my $meta = shift;
    croak q{Missing role or interface specifications}
        unless @_;
    $meta->add_role($_)
        for @_;
    return 1;
}

1;
