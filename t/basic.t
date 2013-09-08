use strictures 1;
use Test::More;

do {
    package MyBasic;
    use Object::Glib;
    use namespace::clean;
    property title => (is => 'rw');
    register;
};

subtest 'no arguments' => sub {
    my $obj = MyBasic->new;
    isa_ok $obj, 'MyBasic', 'basic object';
    $obj->set(title => 'Foo');
    is $obj->get('title'), 'Foo', 'set/get access';
    is $obj->get_title, 'Foo', 'get_title';
    $obj->set_title('Bar');
    is $obj->get_title, 'Bar', 'get_title after set_title';
};

done_testing;
