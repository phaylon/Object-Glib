use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;
use Object::Glib::TestProperty;

group 'reader option' => sub {
    my $class = TestProperty(is => 'bare', reader => 'prop');
    test_accessors($class, 'prop', 0, 0, 0, 0);
    my $obj = $class->new(prop => 23);
    is $obj->prop, 23, 'custom reader';
    like exception {
        $obj->get('prop');
    }, qr{cannot be read directly}, 'direct read error';
    like exception {
        $obj->set(prop => 43);
    }, qr{cannot be written directly}, 'direct write error';
};

group 'writer option' => sub {
    my $class = TestProperty(reader => 'read', writer => 'write');
    test_accessors($class, 'prop', 0, 0, 0, 0);
    my $obj = $class->new;
    is $obj->write(23), 1, 'custom writer';
    is $obj->read, 23, 'value after custom write';
    like exception {
        $obj->get('prop');
    }, qr{cannot be read directly}, 'direct read error';
    like exception {
        $obj->set(prop => 43);
    }, qr{cannot be written directly}, 'direct write error';
};

done_testing;
