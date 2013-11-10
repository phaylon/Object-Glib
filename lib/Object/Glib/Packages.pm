use strictures 1;

package Object::Glib::Packages;
use Module::Runtime qw( use_module );
use Carp qw( croak );
use Object::Glib::Types qw( :oo );

use namespace::clean;
use Exporter 'import';

our @EXPORT_OK = qw(
    deparse_package
);

sub deparse_package {
    my ($package, $title) = @_;
    if (ref($package) eq 'ARRAY') {
        croak join ' ',
            qq{A packaged $title definition},
            qq{needs a module and namespaced package},
            unless @$package == 2;
        my ($module, $subpackage) = @$package;
        croak qq{Invalid $title package module}
            unless is_class($module);
        croak qq{Invalid $title package}
            unless is_class($subpackage);
        $package = join '::', $module, $subpackage;
        use_module($module)
            unless $package->can('new');
        $module->init
            if $module->can('init');
    }
    else {
        croak q{Invalid superclass}
            unless is_class($package);
        use_module($package)
            unless $package->can('new');
    }
    return $package;
};

1;
