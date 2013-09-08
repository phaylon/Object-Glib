use strictures 1;

package Object::Glib::TestProperty;
use Package::Variant
    importing => ['Object::Glib'],
    subs => [qw( property register )];

sub make_variant {
    my ($class, $package, %arg) = @_;
    property prop => %arg;
    my $methods = delete($arg{_}) || {};
    install $_ => $methods->{ $_ }
        for keys %$methods;
    register;
}

1;
