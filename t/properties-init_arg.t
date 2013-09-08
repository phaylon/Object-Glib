use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;
use Object::Glib::TestProperty;

group 'undefined init_arg' => sub {
    my $class = TestProperty(
        is => 'ro',
        init_arg => undef,
        default => sub { 23 },
    );
    like exception { $class->new(prop => 42) },
        qr{Unknown constructor arguments.+prop},
        'error thrown with init_arg present';
};

group 'redefined init_arg' => sub {
    my $class = TestProperty(
        is => 'ro',
        init_arg => 'value',
        default => sub { 23 },
    );
    like exception { $class->new(prop => 42) },
        qr{Unknown constructor arguments.+prop},
        'error thrown with init_arg present';
    my $obj = $class->new(value => 42);
    is $obj->get_prop, 42, 'right value in property';
};

done_testing;
