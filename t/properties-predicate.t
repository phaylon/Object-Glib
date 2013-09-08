use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;
use Object::Glib::TestProperty;

subtest 'custom name' => sub {
    my $class = TestProperty(is => 'rw', predicate => 'has_prop');
    my $obj = $class->new;
    ok !$obj->has_prop, 'false without value';
    $obj->set_prop(23);
    ok $obj->has_prop, 'true with value';
};

subtest 'auto named' => sub {
    my $class = TestProperty(is => 'rw', predicate => 1);
    my $obj = $class->new;
    ok !$obj->_has_prop, 'false without value';
    $obj->set_prop(23);
    ok $obj->_has_prop, 'true with value';
};

subtest 'lazy' => sub {
    my $class = TestProperty(
        is => 'ro',
        default => sub { 23 },
        predicate => 1,
        lazy => 1,
    );
    my $obj = $class->new;
    ok !$obj->_has_prop, 'no value yet';
    $obj->get_prop;
    ok $obj->_has_prop, 'value after default';
};

done_testing;
