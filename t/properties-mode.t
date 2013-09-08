use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;
use Object::Glib::TestProperty;

my $is_ro = TestProperty(is => 'ro');

group 'is ro without value' => sub {
    test_accessors($is_ro, 'prop', 1, 0, 0, 0);
    my $obj = $is_ro->new;
    is $obj->get('prop'), undef, 'undef by default';
    is $obj->get_prop, undef, 'undef via reader';
    like exception { $obj->set(prop => 23) },
        qr{Property 'prop' cannot be written directly},
        'direct set';
};

group 'is ro with value' => sub {
    my $obj = $is_ro->new(prop => 23);
    is $obj->get('prop'), 23, 'constructor arg direct';
    is $obj->get_prop, 23, 'constructor arg via reader';
    like exception { $obj->set(prop => 23) },
        qr{Property 'prop' cannot be written directly},
        'direct set';
};

group 'is rw' => sub {
    my $is_rw = TestProperty(is => 'rw');
    test_accessors($is_rw, 'prop', 1, 1, 0, 0);
    my $obj = $is_rw->new;
    is $obj->get_prop, undef, 'undef by default';
    is $obj->set_prop(23), 1, 'writer';
    is $obj->get_prop, 23, 'value after set';
};

group 'is rpo' => sub {
    my $is_rpo = TestProperty(is => 'rpo');
    test_accessors($is_rpo, 'prop', 0, 0, 1, 0);
    my $obj = $is_rpo->new(prop => 23);
    is $obj->_get_prop, 23, 'value via private reader';
    like exception {
        $obj->set(prop => 43);
    }, qr{cannot be written directly}, 'direct write error';
};

group 'is rpwp' => sub {
    my $is_rpwp = TestProperty(is => 'rpwp');
    test_accessors($is_rpwp, 'prop', 0, 0, 1, 1);
    my $obj = $is_rpwp->new(prop => 23);
    is $obj->_get_prop, 23, 'value via private reader';
    is $obj->_set_prop(42), 1, 'private writer';
    is $obj->_get_prop, 42, 'value after private set';
    like exception {
        $obj->get('prop');
    }, qr{cannot be read directly}, 'direct read error';
    like exception {
        $obj->set(prop => 43);
    }, qr{cannot be written directly}, 'direct write error';
};

group 'is rwp' => sub {
    my $is_rwp = TestProperty(is => 'rwp');
    test_accessors($is_rwp, 'prop', 1, 0, 0, 1);
    my $obj = $is_rwp->new(prop => 23);
    is $obj->get_prop, 23, 'public reader';
    is $obj->_set_prop(42), 1, 'private writer';
    is $obj->get_prop, 42, 'value after public writer';
    is $obj->get('prop'), 42, 'direct read';
    like exception {
        $obj->set(prop => 43);
    }, qr{cannot be written directly}, 'direct write error';
};

group 'is bare' => sub {
    my $is_bare = TestProperty(is => 'bare');
    test_accessors($is_bare, 'prop', 0, 0, 0, 0);
    my $obj = $is_bare->new;
    like exception {
        $obj->get('prop');
    }, qr{cannot be read directly}, 'direct read error';
    like exception {
        $obj->set(prop => 43);
    }, qr{cannot be written directly}, 'direct write error';
};

group 'is lazy' => sub {
    my $n = 23;
    my $is_lazy = TestProperty(is => 'lazy', default => sub { $n++ });
    test_accessors($is_lazy, 'prop', 0, 0, 0, 0);
    my $obj = $is_lazy->new;
    is $n, 23, 'default not called';
    like exception {
        $obj->get('prop');
    }, qr{cannot be read directly}, 'direct read error';
    like exception {
        $obj->set(prop => 43);
    }, qr{cannot be written directly}, 'direct write error';
};

done_testing;
