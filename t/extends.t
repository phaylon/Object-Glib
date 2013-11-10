use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;

do {
    package MyTestInvalidSuper;
    use Object::Glib;
};

my @_invalid_super = (
    [[],
        qr{Missing superclass definition},
        'no argument'],
    [[undef],
        qr{Missing superclass definition},
        'undef argument'],
    [[[]],
        qr{A packaged superclass definition needs a module and namespaced},
        'empty packaged'],
    [[['Gtk2']],
        qr{A packaged superclass definition needs a module and namespaced},
        'only module'],
    [[['Gtk2', 'Label', 'ThisShouldNotBeHere']],
        qr{A packaged superclass definition needs a module and namespaced},
        'too many parts'],
    [[['', 'Label']],
        qr{Invalid superclass package module},
        'invalid module'],
    [[[undef, 'Label']],
        qr{Invalid superclass package module},
        'undefined module'],
    [[['Gtk2', '']],
        qr{Invalid superclass package},
        'invalid module class'],
    [[['Gtk2', undef]],
        qr{Invalid superclass package},
        'undefined module class'],
    [[''],
        qr{Invalid superclass},
        'invalid superclass'],
);

group 'invalid superclass' => sub {
    for my $test (@_invalid_super) {
        my ($super, $rx, $title) = @$test;
        like exception {
            package MyTestInvalidSuper;
            extends @$super;
        }, $rx, $title;
    }
};

group 'packaged superclass with init' => sub {
    is exception {
        package MyTestPackagedSuperInit;
        use Object::Glib;
        extends ['Object::Glib::TestClass::PackageInit', 'Class'];
        register;
    }, undef, 'no errors for packaged superclass';
    is 'MyTestPackagedSuperInit'->loaded,
        'init 1',
        'object isa packaged class and init was called';
};

group 'packaged superclass without init' => sub {
    is exception {
        package MyTestPackagedSuperNoInit;
        use Object::Glib;
        extends ['Object::Glib::TestClass::PackageNoInit', 'Class'];
        register;
    }, undef, 'no errors for packaged superclass';
    is 'MyTestPackagedSuperNoInit'->loaded,
        23,
        'object isa packaged class';
};
    
done_testing;
