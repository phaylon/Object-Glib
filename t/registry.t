use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;
use Import::Into;
use Object::Glib ();
use Object::Glib::Registry qw( find_meta );

like exception {
    package MyTestMultiImport;
    Object::Glib->import::into(__PACKAGE__)
        for 1, 2;
}, qr{Object::Glib is already imported into MyTestMultiImport},
    'multiple imports';

like exception {
    find_meta('MyTestNoImport');
}, qr{Object::Glib was not imported into MyTestNoImport},
    'meta for non object-glib package';

done_testing;
