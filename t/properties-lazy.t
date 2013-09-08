use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;
use Object::Glib::TestProperty;

subtest 'is ro, default, no value' => sub {
    my $n = 23;
    my $lazy_ro = TestProperty(
        is => 'ro',
        lazy => 1,
        default => sub { $n++ },
    );
    my $obj = $lazy_ro->new;
    is $n, 23, 'default not yet called';
    is $obj->get_prop, 23, 'lazy default calculated';
    is $obj->get_prop, 23, 'lazy default sticks';
    is $obj->get('prop'), 23, 'lazy default direct';
    is $n, 24, 'default called once';
};

subtest 'is ro, default, with value' => sub {
    my $n = 23;
    my $lazy_ro = TestProperty(
        is => 'ro',
        lazy => 1,
        default => sub { $n++ },
    );
    my $obj = $lazy_ro->new(prop => 42);
    is $n, 23, 'default not called';
    is $obj->get_prop, 42, 'constructor value';
    is $n, 23, 'default still not called';
};

done_testing;
