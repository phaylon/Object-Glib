use strictures 1;

package Object::Glib::Test;
use Test::More ();

use namespace::clean;
use Exporter 'import';

our @EXPORT = qw(
    test_accessors
    group
);

sub group {
    my ($title, $code) = @_;
    Test::More::note $title;
    if ($ENV{HARNESS_ACTIVE}) {
        $code->();
    }
    else {
        Test::More::subtest $title, $code;
    }
    return 1;
}

sub test_accessors {
    my ($class, $name, $r_pub, $w_pub, $r_pri, $w_pri) = @_;
    my $can = sub { $_[0]->can($_[1]) ? 1 : 0 };
    Test::More::ok $class->$can("get_$name") eq $r_pub, 'public reader';
    Test::More::ok $class->$can("set_$name") eq $w_pub, 'public writer';
    Test::More::ok $class->$can("_get_$name") eq $r_pri, 'private reader';
    Test::More::ok $class->$can("_set_$name") eq $w_pri, 'private writer';
}


1;
