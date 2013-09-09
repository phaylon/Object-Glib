use strictures 1;

package Object::Glib::Types;
use List::MoreUtils qw( uniq );

use namespace::clean;
use Exporter 'import';

our %EXPORT_TAGS = (
    ref => [qw(
        isa_code maybe_code
        isa_array maybe_array
    )],
    oo => [qw(
        isa_class maybe_class
    )],
    ident => [qw(
        isa_ident maybe_ident
        isa_auto_ident maybe_auto_ident
        isa_code_ident maybe_code_ident
    )],
    val => [qw(
        isa_int_pos0 maybe_int_pos0
    )],
);
our @EXPORT_OK = uniq map { (@$_) } values %EXPORT_TAGS;
$EXPORT_TAGS{all} = [@EXPORT_OK];

my $_is_ident = sub {
    return undef
        unless defined($_[0])
        and $_[0] =~ m{\A[a-z_][a-z_0-9]*\z}ig;
};

sub isa_int_pos0 {
    die "Not an integer at 0 or above\n"
        unless defined($_[0])
        and $_[0] =~ m{\A[0-9]+\z};
}

sub isa_class {
    die "Invalid class name\n"
        unless defined($_[0])
        and length $_[0];
}

sub isa_ident {
    die "Invalid identifier\n"
        unless $_[0]->$_is_ident;
}

sub isa_auto_ident {
    die "Expected identifier or 1 for automatic naming\n"
        unless defined($_[0]) and (
            $_[0] eq 1
            or $_[0]->$_is_ident
        );
}

sub isa_code_ident {
    die "Expected identifier, code reference or 1 for automatic naming\n"
        unless defined($_[0]) and (
            $_[0] eq 1
            or ref $_[0] eq 'CODE'
            or $_[0]->$_is_ident
        );
}

sub isa_array {
    die "Not an array reference\n"
        unless defined($_[0])
        and ref $_[0] eq 'ARRAY';
}

sub isa_code {
    die "Not a code reference\n"
        unless defined($_[0])
        and ref $_[0] eq 'CODE';
}

my $_maybe_variant = sub {
    my ($code) = @_;
    return sub {
        return unless defined $_[0];
        $_[0]->$code;
    };
};

*maybe_class = $_maybe_variant->(\&isa_class);
*maybe_code = $_maybe_variant->(\&isa_code);
*maybe_array = $_maybe_variant->(\&isa_array);
*maybe_code_ident = $_maybe_variant->(\&isa_code_ident);
*maybe_auto_ident = $_maybe_variant->(\&isa_auto_ident);
*maybe_ident = $_maybe_variant->(\&isa_ident);
*maybe_int_pos0 = $_maybe_variant->(\&isa_int_pos0);

1;
