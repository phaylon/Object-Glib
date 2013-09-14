use strictures 1;

package Object::Glib::Values;
use Data::Dump qw( pp );

use namespace::clean;
use Exporter 'import';

our @EXPORT_OK = qw(
    identify
);

my %_ref_identity = map { ($_, 1) } qw(
    HASH ARRAY SCALAR CODE GLOB
    Regexp
);

sub identify {
    my ($value) = @_;
    return 'undefined'
        unless defined $value;
    my $ref = ref $value;
    unless ($ref) {
        $value = substr($value, 0, 20) . '...'
            if length($value) > 25;
        return pp($value);
    }
    if ($_ref_identity{ $ref }) {
        return sprintf '%s reference', lc $ref;
    }
    return "instance of $ref";
}

1;
