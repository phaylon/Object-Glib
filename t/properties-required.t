use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;
use Object::Glib::TestProperty;

group 'required option' => sub {
    my $class = TestProperty(
        is => 'ro',
        required => 1,
    );
    is $class->new(prop => 23)->get_prop, 23, 'no error with value';
    like exception { $class->new },
        qr{Missing constructor arguments.+prop},
        'error without value';
};

done_testing;
