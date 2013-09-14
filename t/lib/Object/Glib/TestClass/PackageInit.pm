use strictures 1;

my $_init_count = 0;

package Object::Glib::TestClass::PackageInit;
sub init { $_init_count++ }

package Object::Glib::TestClass::PackageInit::Class;
use Object::Glib;
sub loaded { join ' ', 'init', $_init_count }
register;

1;
