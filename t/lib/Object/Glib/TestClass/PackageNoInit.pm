use strictures 1;

package Object::Glib::TestClass::PackageNoInit;

package Object::Glib::TestClass::PackageNoInit::Class;
use Object::Glib;
sub loaded { 23 }
register;

1;
