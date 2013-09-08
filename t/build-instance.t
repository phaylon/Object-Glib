use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;

my @_calls;

do {
    package TestParent;
    use Object::Glib;
    property prop => (is => 'ro');
    sub BUILD_INSTANCE {
        my ($self, $attrs) = @_;
        push @_calls, ['parent', {%$attrs}];
        delete $attrs->{ignore};
    }
    register;
};

do {
    package TestChild;
    use Object::Glib;
    extends 'TestParent';
    sub BUILD_INSTANCE {
        my ($self, $attrs) = @_;
        push @_calls, ['child', {%$attrs}];
    }
    register;
};

TestChild->new(prop => 23);
is_deeply \@_calls, [
    ['parent', { prop => 23 }],
    ['child', { prop => 23 }],
], 'calls with only known property';

@_calls = ();
TestChild->new(prop => 23, ignore => 42);
is_deeply \@_calls, [
    ['parent', { prop => 23, ignore => 42 }],
    ['child', { prop => 23 }],
], 'calls with ignored property';

@_calls = ();
like exception { TestChild->new(prop => 23, unknown => 42) },
    qr{Unknown constructor arguments.+unknown},
    'unhandled argument error';
is_deeply \@_calls, [
    ['parent', { prop => 23, unknown => 42 }],
    ['child', { prop => 23, unknown => 42 }],
], 'calls with unknown property';

done_testing;
