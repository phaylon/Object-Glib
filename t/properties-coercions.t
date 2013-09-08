use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;
use Object::Glib::TestProperty;

group 'coerce option' => sub {
    my $call = 0;
    my $class = TestProperty(
        is => 'rw',
        coerce => sub { $call++; die "FAIL\n" unless $_[0]; [shift] },
    );
    is $class->new->get_prop, undef, 'undef by default';
    is $call, 0, 'coercion not called';
    is_deeply $class->new(prop => 23)->get_prop, [23],
        'coerced on construct';
    is $call, 1, 'coercion called';
    like exception { $class->new(prop => 0) },
        qr{Property 'prop' initialisation error: FAIL},
        'coerce failure on construct';
    is $call, 2, 'coercion called once';
    $call = 0;
    my $obj = $class->new;
    is $obj->set_prop(42), 1, 'write without error';
    is_deeply $obj->get_prop, [42], 'correct value';
    is $call, 1, 'check called on write';
    like exception { $obj->set_prop(0) },
        qr{Property 'prop' initialisation error: FAIL},
        'coerce failure on write';
};

done_testing;
