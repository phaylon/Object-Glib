use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;

do {
    package TestParent;
    use Object::Glib;
    property foo => (is => 'rw', builder => sub { 23 });
    register
};

do {
    package TestChild;
    use Object::Glib;
    extends 'TestParent';
    property bar => (is => 'rw', builder => sub { 42 });
    around _build_foo => sub {
        my ($orig, $self) = @_;
        return $self->$orig * 2;
    };
    register;
};

my $obj = TestChild->new;
is $obj->get_foo, 46, 'parent attribute';
is $obj->get_bar, 42, 'child attribute';

done_testing;
