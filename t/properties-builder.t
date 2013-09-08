use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;
use Object::Glib::TestProperty;

group 'lazy' => sub {
    group 'auto named' => sub {
        my $n = 23;
        my $class = TestProperty(
            is => 'ro',
            lazy => 1,
            builder => 1,
            _ => { _build_prop => sub { $n++ } },
        );
        my $obj = $class->new;
        is $n, 23, 'builder not yet run';
        is $obj->get_prop, 23, 'value calculated';
        is $obj->get_prop, 23, 'value stable';
        is $n, 24, 'builder only called once';
    };
    group 'directly named' => sub {
        my $n = 23;
        my $class = TestProperty(
            is => 'ro',
            lazy => 1,
            builder => 'make_prop',
            _ => { make_prop => sub { $n++ } },
        );
        my $obj = $class->new;
        is $n, 23, 'builder not yet run';
        is $obj->get_prop, 23, 'value calculated';
        is $obj->get_prop, 23, 'value stable';
        is $n, 24, 'builder only called once';
    };
    group 'installed' => sub {
        my $n = 23;
        my $class = TestProperty(
            is => 'ro',
            lazy => 1,
            builder => sub { $n++ },
        );
        my $obj = $class->new;
        is $n, 23, 'builder not yet run';
        is $obj->get_prop, 23, 'value calculated';
        is $obj->get_prop, 23, 'value stable';
        is $n, 24, 'builder only called once';
        $n = 23;
        my $extended;
        my $xclass = do {
            package TestOverrideLazyBuilder;
            use Object::Glib;
            extends $class;
            after _build_prop => sub { $extended++ };
            register;
            __PACKAGE__;
        };
        my $xobj = $xclass->new;
        is $xobj->get_prop, 23, 'extended calculated';
        is $extended, 1, 'extended builder called';
    };
    group 'constructor override' => sub {
        my $n = 23;
        my $class = TestProperty(
            is => 'ro',
            builder => sub { $n++ },
            lazy => 1,
        );
        my $obj = $class->new(prop => 42);
        is $n, 23, 'builder not called';
        is $obj->get_prop, 42, 'override value';
        is $n, 23, 'builder still not called';
    };
    group 'writer override' => sub {
        my $n = 23;
        my $class = TestProperty(
            is => 'rw',
            builder => sub { $n++ },
            lazy => 1,
        );
        my $obj = $class->new;
        is $n, 23, 'builder not called';
        is $obj->set_prop(42), 1, 'writer';
        is $obj->get_prop, 42, 'override value';
        is $n, 23, 'builder still not called';
    };
};

group 'non lazy' => sub {
    group 'auto named' => sub {
        my $n = 23;
        my $class = TestProperty(
            is => 'ro',
            builder => 1,
            _ => { _build_prop => sub { $n++ } },
        );
        my $obj = $class->new;
        is $n, 24, 'builder was run';
        is $obj->get_prop, 23, 'value calculated';
        is $obj->get_prop, 23, 'value stable';
        is $n, 24, 'builder only called once';
    };
    group 'directly named' => sub {
        my $n = 23;
        my $class = TestProperty(
            is => 'ro',
            builder => 'make_prop',
            _ => { make_prop => sub { $n++ } },
        );
        my $obj = $class->new;
        is $n, 24, 'builder was run';
        is $obj->get_prop, 23, 'value calculated';
        is $obj->get_prop, 23, 'value stable';
        is $n, 24, 'builder only called once';
    };
    group 'installed' => sub {
        my $n = 23;
        my $class = TestProperty(
            is => 'ro',
            builder => sub { $n++ },
        );
        my $obj = $class->new;
        is $n, 24, 'builder was run';
        is $obj->get_prop, 23, 'value calculated';
        is $obj->get_prop, 23, 'value stable';
        is $n, 24, 'builder only called once';
        $n = 23;
        my $extended;
        my $xclass = do {
            package TestOverrideNonLazyBuilder;
            use Object::Glib;
            extends $class;
            after _build_prop => sub { $extended++ };
            register;
            __PACKAGE__;
        };
        my $xobj = $xclass->new;
        is $extended, 1, 'extended builder called';
        is $n, 24, 'extended builder was run';
        is $xobj->get_prop, 23, 'extended calculated';
    };
    group 'constructor override' => sub {
        my $n = 23;
        my $class = TestProperty(
            is => 'ro',
            builder => sub { $n++ },
        );
        my $obj = $class->new(prop => 42);
        is $n, 23, 'builder not called';
        is $obj->get_prop, 42, 'override value';
        is $n, 23, 'builder still not called';
    };
};

done_testing;
