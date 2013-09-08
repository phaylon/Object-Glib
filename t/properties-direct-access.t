use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;
use Object::Glib::TestProperty;

group 'writable option' => sub {
    group 'writable' => sub {
        my $class = TestProperty(
            is => 'bare',
            writable => 1,
            readable => 1,
        );
        test_accessors($class, 'prop', 0, 0, 0, 0);
        my $obj = $class->new;
        is $obj->get('prop'), undef, 'undef by default';
        $obj->set(prop => 23);
        is $obj->get('prop'), 23, 'after direct write';
    };
    group 'not writable' => sub {
        my $class = TestProperty(
            is => 'bare',
            writable => 0,
            readable => 1,
        );
        test_accessors($class, 'prop', 0, 0, 0, 0);
        my $obj = $class->new(prop => 23);
        is $obj->get('prop'), 23, 'constructor value';
        like exception { $obj->set(prop => 23) },
            qr{cannot be written directly},
            'direct write error';
    };
};

group 'readable option' => sub {
    group 'not readable' => sub {
        my $class = TestProperty(
            is => 'ro',
            writable => 1,
            readable => 0,
        );
        test_accessors($class, 'prop', 1, 0, 0, 0);
        my $obj = $class->new(prop => 23);
        is $obj->get_prop, 23, 'public reader';
        like exception { $obj->get('prop') },
            qr{cannot be read directly},
            'direct read error';
        $obj->set(prop => 42);
        is $obj->get_prop, 42, 'value after private write';
    };
};

done_testing;
