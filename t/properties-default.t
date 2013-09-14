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
        default => sub { $n++ },
        lazy => 1,
    );
    my $obj = $class->new;
    is $n, 23, 'default not yet run';
    is $obj->get_prop, 23, 'value';
    is $obj->get_prop, 23, 'value stable';
    is $n, 24, 'default only called once';
};

group 'non lazy' => sub {
    my $n = 23;
    my $class = TestProperty(
        is => 'ro',
        default => sub { $n++ },
    );
    my $obj = $class->new;
    is $n, 24, 'default was run';
    is $obj->get_prop, 23, 'value';
    is $obj->get_prop, 23, 'value stable';
    is $n, 24, 'default only called once';
};

group 'constructor override' => sub {
    my $n = 23;
    my $class = TestProperty(
        is => 'ro',
        default => sub { $n++ },
    );
    my $obj = $class->new(prop => 42);
    is $n, 23, 'default not called';
    is $obj->get_prop, 42, 'value';
    is $obj->get_prop, 42, 'value stable';
    is $n, 23, 'default still not called';
};

group 'lazy constructor override' => sub {
    my $n = 23;
    my $class = TestProperty(
        is => 'ro',
        lazy => 1,
        default => sub { $n++ },
    );
    my $obj = $class->new(prop => 42);
    is $n, 23, 'default not called';
    is $obj->get_prop, 42, 'value';
    is $obj->get_prop, 42, 'value stable';
    is $n, 23, 'default still not called';
};

group 'writer override' => sub {
    my $n = 23;
    my $class = TestProperty(
        is => 'rw',
        lazy => 1,
        default => sub { $n++ },
    );
    my $obj = $class->new;
    is $n, 23, 'default not called';
    is $obj->set_prop(42), 1, 'writer';
    is $obj->get_prop, 42, 'value';
    is $obj->get_prop, 42, 'value stable';
    is $n, 23, 'default still not called';
};

like exception { TestProperty(default => sub { 23 }, required => 1) },
    qr{A defaulted property cannot be required},
    'default and required';

like exception { TestProperty(required => 1, init_arg => undef) },
    qr{A required property needs an init_arg},
    'required without init_arg';

like exception { TestProperty(builder => sub {}, default => sub {}) },
    qr{A property cannot have a default and a builder},
    'default and builder';

like exception { TestProperty(lazy => 1, builder => undef) },
    qr{A lazy property needs a builder or default},
    'lazy without default or builder';

done_testing;
