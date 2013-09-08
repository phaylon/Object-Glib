use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;
use Object::Glib::TestProperty;

group 'lazy' => sub {
    my $n = 23;
    my $class = TestProperty(
        is => 'ro',
        clearer => 'clear',
        lazy => 1,
        default => sub { $n++ },
    );
    my $obj = $class->new;
    is $n, 23, 'default not yet called';
    is $obj->get_prop, 23, 'default value';
    is $obj->get_prop, 23, 'default value is stable';
    is $n, 24, 'default called';
    is $obj->clear, 1, 'clearer';
    is $n, 24, 'default not called after clear';
    is $obj->get_prop, 24, 'new value';
    is $n, 25, 'default called once for new value';
};

group 'non lazy' => sub {
    my $n = 23;
    my $class = TestProperty(
        is => 'ro',
        clearer => 'clear',
        default => sub { $n++ },
    );
    my $obj = $class->new;
    is $n, 24, 'default was called';
    is $obj->get_prop, 23, 'default value';
    is $obj->get_prop, 23, 'default value is stable';
    is $n, 24, 'default not called again';
    is $obj->clear, 1, 'clearer';
    is $n, 24, 'default not called after clear';
    is $obj->get_prop, undef, 'no new value';
    is $n, 24, 'default not called after read';
};

group 'auto named' => sub {
    my $n = 23;
    my $class = TestProperty(
        is => 'ro',
        clearer => 1,
        lazy => 1,
        default => sub { $n++ },
    );
    my $obj = $class->new;
    is $n, 23, 'default not yet called';
    is $obj->get_prop, 23, 'default value';
    is $obj->get_prop, 23, 'default value is stable';
    is $n, 24, 'default called';
    is $obj->_clear_prop, 1, 'clearer';
    is $n, 24, 'default not called after clear';
    is $obj->get_prop, 24, 'new value';
    is $n, 25, 'default called once for new value';
};

done_testing;
