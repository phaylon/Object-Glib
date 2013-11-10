use strictures 1;

package Object::Glib::Role;
use parent 'Object::Glib::Exporter::Common';
use Carp qw( croak );
use Import::Into;
use Object::Glib::CarpGroup;
use Object::Glib::Exporter;
use Role::Tiny ();

use aliased 'Object::Glib::Meta::Role';

use namespace::clean;

setup_exports(
    meta_class => Role,
    export => [qw(
        property
        signal
    )],
    override_after => [qw(
        with
    )],
    finalize => sub {
        my ($package) = @_;
        Role::Tiny->import::into($package);
        strictures->import::into($package, 1);
        return 1;
    },
);

1;
