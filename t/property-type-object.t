use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;
use Object::Glib::TestProperty;

do {
    package TestObject;
    use Moo;
    has text => (is => 'ro');
    sub join { join '', $_[0]->text, @_[1 .. $#_] }
};

do {
    package WrongObject;
    use Moo;
};

my $ok = TestObject->new(text => 'foo');
my $err = WrongObject->new;

group 'plain' => sub {
    my $class = TestProperty(
        type => 'Object',
        is => 'rw',
    );
    my $obj = $class->new;
    is $obj->set_prop($ok), 1, 'correct class';
    is $obj->set_prop($err), 1, 'other class';
    like exception { $obj->set_prop([]) },
        qr{Property 'prop' value error: Not an object},
        'non object';
};

group 'class option' => sub {
    my $class = TestProperty(
        type => 'Object',
        is => 'rw',
        class => 'TestObject',
    );
    my $obj = $class->new;
    is $obj->set_prop($ok), 1, 'correct class';
    like exception { $obj->set_prop($err) },
        qr{Property 'prop' value error: Not an instance of TestObject},
        'wrong class';
    like exception { $obj->set_prop([]) },
        qr{Property 'prop' value error: Not an instance of TestObject},
        'non object';
    like exception { $class->new(prop => $err) },
        qr{Property 'prop' value error: Not an instance of TestObject},
        'wrong object for constructor';
};

group 'delegation' => sub {
    group 'mapping' => sub {
        my $class = TestProperty(
            type => 'Object',
            is => 'rw',
            handles => {
                get_foo => 'text',
                get_foobar => ['join', 'bar'],
            },
        );
        my $obj = $class->new(prop => $ok);
        is $obj->get_foo, 'foo', 'direct';
        is $obj->get_foobar, 'foobar', 'curried';
    };
    group 'list' => sub {
        my $class = TestProperty(
            type => 'Object',
            is => 'rw',
            handles => ['text'],
        );
        my $obj = $class->new(prop => $ok);
        is $obj->text, 'foo', 'direct';
    };
};

done_testing;
