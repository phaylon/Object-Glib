use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;
use Object::Glib::TestProperty;

subtest 'isa option' => sub {
    my $call = 0;
    my $class = TestProperty(
        is => 'rw',
        isa => sub { $call++; die "FAIL\n" unless $_[0] },
    );
    is $class->new->get_prop, undef, 'not checked without value';
    is $call, 0, 'constraint not called';
    is $class->new(prop => 23)->get_prop, 23, 'check passed';
    is $call, 1, 'constraint called';
    like exception { $class->new(prop => 0) },
        qr{Property 'prop' initialisation error: FAIL},
        'check failed';
    is $call, 2, 'constraint called once';
    $call = 0;
    my $obj = $class->new;
    is $obj->set_prop(42), 1, 'write without error';
    is $call, 1, 'check called on write';
    is $obj->get_prop, 42, 'correct value';
    like exception { $obj->set_prop(0) },
        qr{Property 'prop' initialisation error: FAIL},
        'check failed on write';
};

done_testing;
