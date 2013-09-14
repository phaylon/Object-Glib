use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;

like exception {
    package MyTestNoPropArgs;
    use Object::Glib;
    property;
}, qr{Missing property name}, 'no property arguments';

like exception {
    package MyTestWrongArgs;
    use Object::Glib;
    property foo => 23;
}, qr{Expected property name followed by key/value list},
    'no property arguments';

done_testing;
