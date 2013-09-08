use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::TestProperty;

my $test_accessors = sub {
    my ($class, $r_pub, $w_pub, $r_pri, $w_pri) = @_;
    my $can = sub { $_[0]->can($_[1]) ? 1 : 0 };
    ok $class->$can('get_prop') eq $r_pub, 'public reader';
    ok $class->$can('set_prop') eq $w_pub, 'public writer';
    ok $class->$can('_get_prop') eq $r_pri, 'private reader';
    ok $class->$can('_set_prop') eq $w_pri, 'private writer';
};

subtest 'is option' => sub {
    my $is_ro = TestProperty(is => 'ro');
    subtest 'is ro without value' => sub {
        $is_ro->$test_accessors(1, 0, 0, 0);
        my $obj = $is_ro->new;
        is $obj->get('prop'), undef, 'undef by default';
        is $obj->get_prop, undef, 'undef via reader';
        like exception { $obj->set(prop => 23) },
            qr{Property 'prop' cannot be written directly},
            'direct set';
    };
    subtest 'is ro with value' => sub {
        my $obj = $is_ro->new(prop => 23);
        is $obj->get('prop'), 23, 'constructor arg direct';
        is $obj->get_prop, 23, 'constructor arg via reader';
        like exception { $obj->set(prop => 23) },
            qr{Property 'prop' cannot be written directly},
            'direct set';
    };
    subtest 'is rw' => sub {
        my $is_rw = TestProperty(is => 'rw');
        $is_rw->$test_accessors(1, 1, 0, 0);
        my $obj = $is_rw->new;
        is $obj->get_prop, undef, 'undef by default';
        is $obj->set_prop(23), 1, 'writer';
        is $obj->get_prop, 23, 'value after set';
    };
    subtest 'is rpo' => sub {
        my $is_rpo = TestProperty(is => 'rpo');
        $is_rpo->$test_accessors(0, 0, 1, 0);
        my $obj = $is_rpo->new(prop => 23);
        is $obj->_get_prop, 23, 'value via private reader';
        like exception {
            $obj->set(prop => 43);
        }, qr{cannot be written directly}, 'direct write error';
    };
    subtest 'is rpwp' => sub {
        my $is_rpwp = TestProperty(is => 'rpwp');
        $is_rpwp->$test_accessors(0, 0, 1, 1);
        my $obj = $is_rpwp->new(prop => 23);
        is $obj->_get_prop, 23, 'value via private reader';
        is $obj->_set_prop(42), 1, 'private writer';
        is $obj->_get_prop, 42, 'value after private set';
        like exception {
            $obj->get('prop');
        }, qr{cannot be read directly}, 'direct read error';
        like exception {
            $obj->set(prop => 43);
        }, qr{cannot be written directly}, 'direct write error';
    };
    subtest 'is rwp' => sub {
        my $is_rwp = TestProperty(is => 'rwp');
        $is_rwp->$test_accessors(1, 0, 0, 1);
        my $obj = $is_rwp->new(prop => 23);
        is $obj->get_prop, 23, 'public reader';
        is $obj->_set_prop(42), 1, 'private writer';
        is $obj->get_prop, 42, 'value after public writer';
        is $obj->get('prop'), 42, 'direct read';
        like exception {
            $obj->set(prop => 43);
        }, qr{cannot be written directly}, 'direct write error';
    };
    subtest 'is bare' => sub {
        my $is_bare = TestProperty(is => 'bare');
        $is_bare->$test_accessors(0, 0, 0, 0);
        my $obj = $is_bare->new;
        like exception {
            $obj->get('prop');
        }, qr{cannot be read directly}, 'direct read error';
        like exception {
            $obj->set(prop => 43);
        }, qr{cannot be written directly}, 'direct write error';
    };
    subtest 'is lazy' => sub {
        my $n = 23;
        my $is_lazy = TestProperty(is => 'lazy', default => sub { $n++ });
        $is_lazy->$test_accessors(0, 0, 0, 0);
        my $obj = $is_lazy->new;
        is $n, 23, 'default not called';
        like exception {
            $obj->get('prop');
        }, qr{cannot be read directly}, 'direct read error';
        like exception {
            $obj->set(prop => 43);
        }, qr{cannot be written directly}, 'direct write error';
    };
};

subtest 'writable option' => sub {
    subtest 'writable' => sub {
        my $class = TestProperty(
            is => 'bare',
            writable => 1,
            readable => 1,
        );
        $class->$test_accessors(0, 0, 0, 0);
        my $obj = $class->new;
        is $obj->get('prop'), undef, 'undef by default';
        $obj->set(prop => 23);
        is $obj->get('prop'), 23, 'after direct write';
    };
    subtest 'not writable' => sub {
        my $class = TestProperty(
            is => 'bare',
            writable => 0,
            readable => 1,
        );
        $class->$test_accessors(0, 0, 0, 0);
        my $obj = $class->new(prop => 23);
        is $obj->get('prop'), 23, 'constructor value';
        like exception { $obj->set(prop => 23) },
            qr{cannot be written directly},
            'direct write error';
    };
};

subtest 'readable option' => sub {
    subtest 'not readable' => sub {
        my $class = TestProperty(
            is => 'ro',
            writable => 1,
            readable => 0,
        );
        $class->$test_accessors(1, 0, 0, 0);
        my $obj = $class->new(prop => 23);
        is $obj->get_prop, 23, 'public reader';
        like exception { $obj->get('prop') },
            qr{cannot be read directly},
            'direct read error';
        $obj->set(prop => 42);
        is $obj->get_prop, 42, 'value after private write';
    };
};

subtest 'reader option' => sub {
    my $class = TestProperty(is => 'bare', reader => 'prop');
    $class->$test_accessors(0, 0, 0, 0);
    my $obj = $class->new(prop => 23);
    is $obj->prop, 23, 'custom reader';
    like exception {
        $obj->get('prop');
    }, qr{cannot be read directly}, 'direct read error';
    like exception {
        $obj->set(prop => 43);
    }, qr{cannot be written directly}, 'direct write error';
};

subtest 'writer option' => sub {
    my $class = TestProperty(reader => 'read', writer => 'write');
    $class->$test_accessors(0, 0, 0, 0);
    my $obj = $class->new;
    is $obj->write(23), 1, 'custom writer';
    is $obj->read, 23, 'value after custom write';
    like exception {
        $obj->get('prop');
    }, qr{cannot be read directly}, 'direct read error';
    like exception {
        $obj->set(prop => 43);
    }, qr{cannot be written directly}, 'direct write error';
};

subtest 'init_arg option' => sub {
    subtest 'undefined init_arg' => sub {
        my $class = TestProperty(
            is => 'ro',
            init_arg => undef,
            default => sub { 23 },
        );
        like exception { $class->new(prop => 42) },
            qr{Unknown constructor arguments.+prop},
            'error thrown with init_arg present';
    };
    subtest 'redefined init_arg' => sub {
        my $class = TestProperty(
            is => 'ro',
            init_arg => 'value',
            default => sub { 23 },
        );
        like exception { $class->new(prop => 42) },
            qr{Unknown constructor arguments.+prop},
            'error thrown with init_arg present';
        my $obj = $class->new(value => 42);
        is $obj->get_prop, 42, 'right value in property';
    };
};

subtest 'lazy option' => sub {
    subtest 'is ro, default, no value' => sub {
        my $n = 23;
        my $lazy_ro = TestProperty(
            is => 'ro',
            lazy => 1,
            default => sub { $n++ },
        );
        my $obj = $lazy_ro->new;
        is $n, 23, 'default not yet called';
        is $obj->get_prop, 23, 'lazy default calculated';
        is $obj->get_prop, 23, 'lazy default sticks';
        is $obj->get('prop'), 23, 'lazy default direct';
        is $n, 24, 'default called once';
    };
    subtest 'is ro, default, with value' => sub {
        my $n = 23;
        my $lazy_ro = TestProperty(
            is => 'ro',
            lazy => 1,
            default => sub { $n++ },
        );
        my $obj = $lazy_ro->new(prop => 42);
        is $n, 23, 'default not called';
        is $obj->get_prop, 42, 'constructor value';
        is $n, 23, 'default still not called';
    };
};

subtest 'builder option' => sub {
    subtest 'lazy' => sub {
        subtest 'auto named' => sub {
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
        subtest 'directly named' => sub {
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
        subtest 'installed' => sub {
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
        subtest 'constructor override' => sub {
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
        subtest 'writer override' => sub {
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
    subtest 'non lazy' => sub {
        subtest 'auto named' => sub {
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
        subtest 'directly named' => sub {
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
        subtest 'installed' => sub {
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
        subtest 'constructor override' => sub {
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
};

subtest 'default option' => sub {
    subtest 'lazy' => sub {
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
    subtest 'non lazy' => sub {
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
    subtest 'constructor override' => sub {
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
    subtest 'lazy constructor override' => sub {
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
    subtest 'writer override' => sub {
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
};

subtest 'isa option' => sub {
    my $call = 0;
    my $class = TestProperty(
        is => 'rw',
        isa => sub { $call++; die "FAIL\n" unless $_[0] },
    );
    is $class->new->get_prop, undef, 'not checked without value';
    is $call, 0, 'constraint not called';
    is $class->new(prop => 23)->get_prop, 23, 'check passed';
    is $call, 1, 'constraint called';
    like exception { $class->new(prop => 0) },
        qr{Property 'prop' initialisation error: FAIL},
        'check failed';
    is $call, 2, 'constraint called once';
    $call = 0;
    my $obj = $class->new;
    is $obj->set_prop(42), 1, 'write without error';
    is $call, 1, 'check called on write';
    is $obj->get_prop, 42, 'correct value';
    like exception { $obj->set_prop(0) },
        qr{Property 'prop' initialisation error: FAIL},
        'check failed on write';
};

subtest 'coerce option' => sub {
    my $call = 0;
    my $class = TestProperty(
        is => 'rw',
        coerce => sub { $call++; die "FAIL\n" unless $_[0]; [shift] },
    );
    is $class->new->get_prop, undef, 'undef by default';
    is $call, 0, 'coercion not called';
    is_deeply $class->new(prop => 23)->get_prop, [23],
        'coerced on construct';
    is $call, 1, 'coercion called';
    like exception { $class->new(prop => 0) },
        qr{Property 'prop' initialisation error: FAIL},
        'coerce failure on construct';
    is $call, 2, 'coercion called once';
    $call = 0;
    my $obj = $class->new;
    is $obj->set_prop(42), 1, 'write without error';
    is_deeply $obj->get_prop, [42], 'correct value';
    is $call, 1, 'check called on write';
    like exception { $obj->set_prop(0) },
        qr{Property 'prop' initialisation error: FAIL},
        'coerce failure on write';
};

subtest 'clearer option' => sub {
    subtest 'lazy' => sub {
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
    subtest 'non lazy' => sub {
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
    subtest 'auto named' => sub {
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
    }
};

subtest 'trigger options' => sub {
    my (@args);
    my ($set, $unset) = (0, 0);
    my $class = TestProperty(
        is => 'rw',
        default => sub { 23 },
        clearer => 1,
        lazy => 1,
        on_set => 1,
        on_unset => 1,
        _ => {
            _on_prop_set => sub {
                shift; push @args, [set => @_]; $set++;
            },
            _on_prop_unset => sub {
                shift; push @args, [unset => @_]; $unset++;
            },
        },
    );
    my $ndef = $class->new;
    is $set, 0, 'not yet set';
    is $unset, 0, 'not yet unset';
    $ndef->set_prop(42);
    is $set, 1, 'set triggered on write';
    is $unset, 0, 'unset not triggered on write without previous';
    $ndef->set_prop(43);
    is $set, 2, 'set triggered on write';
    is $unset, 1, 'unset triggered on write with previous';
    $ndef->_clear_prop;
    is $unset, 2, 'unset triggered on clear';
    is_deeply \@args, [
        [set => 42],
        [unset => 42],
        [set => 43],
        [unset => 43],
    ], 'trigger arguments';
    ($set, $unset) = (0, 0);
    my $def = $class->new(prop => 17);
    is $set, 1, 'set triggered by init';
    is $unset, 0, 'unset not triggered by init';
};

done_testing;
