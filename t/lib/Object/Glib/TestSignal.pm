use strictures 1;

package Object::Glib::TestSignal;
use Package::Variant
    importing => ['Object::Glib'],
    subs => [qw( signal register )];

sub make_variant {
    my ($class, $package, %arg) = @_;
    my $methods = delete($arg{_}) || {};
    signal foo => %arg;
    install $_ => $methods->{ $_ }
        for keys %$methods;
    register;
}

1;
