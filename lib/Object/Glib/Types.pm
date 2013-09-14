use strictures 1;

package Object::Glib::Types;
use List::MoreUtils qw( uniq );
use Object::Glib::Values qw( identify );
use Object::Glib::CarpGroup;

use namespace::clean;
use Exporter 'import';

our %EXPORT_TAGS = (
    ref => [qw(
        isa_code maybe_code
        isa_array maybe_array
        isa_hash maybe_hash
        isa_hash_or_array
    )],
    oo => [qw(
        is_class isa_class maybe_class
    )],
    ident => [qw(
        is_ident isa_ident maybe_ident
        isa_auto_ident maybe_auto_ident
        isa_code_ident maybe_code_ident
    )],
    val => [qw(
        isa_int_pos0 maybe_int_pos0
    )],
);
our @EXPORT_OK = uniq map { (@$_) } values %EXPORT_TAGS;
$EXPORT_TAGS{all} = [@EXPORT_OK];

sub is_ident {
    return undef
        unless defined($_[0])
        and $_[0] =~ m{\A[a-z_][a-z_0-9]*\z}ig;
    return 1;
}

sub isa_int_pos0 {
    die sprintf "Value %s an integer at 0 or above\n", identify($_[0])
        unless defined($_[0])
        and $_[0] =~ m{\A[0-9]+\z};
}

sub is_class {
    return 0
        unless defined($_[0])
        and length $_[0];
}

sub isa_class {
    die sprintf "Invalid class name (%s)\n", identify($_[0])
        unless is_class($_[0]);
}

sub isa_ident {
    die sprintf "Invalid identifier (%s)\n", identify($_[0])
        unless is_ident($_[0]);
}

sub isa_auto_ident {
    die sprintf "Expected identifier or 1 for automatic naming, not %s\n",
        identify($_[0])
        unless defined($_[0]) and (
            $_[0] eq 1
            or is_ident($_[0])
        );
}

sub isa_code_ident {
    die sprintf "Expected identifier, code reference or '1', not %s\n",
        identify($_[0])
        unless defined($_[0]) and (
            $_[0] eq 1
            or ref $_[0] eq 'CODE'
            or is_ident($_[0])
        );
}

sub isa_hash_or_array {
    die sprintf "Expected a hash or array reference, not %s\n",
        identify($_[0])
        unless defined($_[0])
        and (ref $_[0] eq 'ARRAY' or ref $_[0] eq 'HASH');
}

sub isa_hash {
    die sprintf "Expected a hash reference, not %s\n", identify($_[0])
        unless defined($_[0])
        and ref $_[0] eq 'HASH';
}

sub isa_array {
    die sprintf "Expected an array reference, not %s\n", identify($_[0])
        unless defined($_[0])
        and ref $_[0] eq 'ARRAY';
}

sub isa_code {
    die sprintf "Expected a code reference, not %s\n", identify($_[0])
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
*maybe_hash = $_maybe_variant->(\&isa_hash);
*maybe_code_ident = $_maybe_variant->(\&isa_code_ident);
*maybe_auto_ident = $_maybe_variant->(\&isa_auto_ident);
*maybe_ident = $_maybe_variant->(\&isa_ident);
*maybe_int_pos0 = $_maybe_variant->(\&isa_int_pos0);

1;
