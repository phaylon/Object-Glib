use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;
use Object::Glib::TestProperty;

group 'default isa check' => sub {
    my $class = TestProperty(is => 'ro', type => 'Array');
    is_deeply $class->new(prop => [23, 42])->get_prop,
        [23, 42],
        'valid init argument';
    like exception { $class->new(prop => 23) },
        qr{Property 'prop' value error: Not an array reference},
        'invalid init argument type';
};

group 'default value' => sub {
    group 'no overrides' => sub {
        my $class = TestProperty(is => 'ro', type => 'Array');
        is_deeply $class->new->get_prop, [], 'correct value';
        ok $class->can('_build_prop'), 'builder installed';
    };
    group 'builder override' => sub {
        my $class = TestProperty(
            is => 'ro',
            type => 'Array',
            builder => sub { [23, 42] },
        );
        is_deeply $class->new->get_prop, [23, 42], 'correct value';
    };
    group 'default override' => sub {
        my $class = TestProperty(
            is => 'ro',
            type => 'Array',
            default => sub { [23, 42] },
        );
        is_deeply $class->new->get_prop, [23, 42], 'correct value';
    };
};

like exception {
    TestProperty(type => 'Array', signals => { foo => 1 });
}, qr{Unknown property signals: foo},
    'unknown signals';

my $class = TestProperty(
    type => 'Array',
    is => 'ro',
    signals => {
        insert => 1,
        update => 1,
        delete => 1,
    },
    handles => {
        prop_count => 'count',
        prop_all => 'all',
        prop_get => 'get',
        prop_get0 => ['get', 0],
        prop_get_all => 'get_all',
        prop_get01 => ['get_all', 0, 1],
        prop_set => 'set',
        prop_set0 => ['set', 0],
        prop_set_all => 'set_all',
        prop_set_all0 => ['set_all', 0],
        prop_iv => 'iv',
        prop_pop => 'pop',
        prop_push => 'push',
        prop_push0 => ['push', 0],
        prop_shift => 'shift',
        prop_unshift => 'unshift',
        prop_unshift0 => ['unshift', 0],
        prop_map => 'map',
        prop_map_prefix => ['map', sub { "$_[0]-$_[1]: $_" }],
        prop_grep => 'grep',
        prop_grep_mod => ['grep', sub { $_ % $_[1] }],
        prop_first => 'first',
        prop_first_nmod => ['first', sub { not $_ % $_[1] }],
        prop_ifirst => 'first_index',
        prop_ifirst_mod => ['first_index', sub { $_ % $_[1] }],
        prop_exists => 'exists',
        prop_exists0 => ['exists', 0],
        prop_exists20 => ['exists', 20],
    },
);

group 'introspection' => sub {
    my $obj = $class->new(prop => [23, 42, 99]);
    is $obj->prop_count, 3, 'count()';
    is_deeply [$obj->prop_iv], [[0, 23], [1, 42], [2, 99]], 'iv()';
};

group 'accessing' => sub {
    my $obj = $class->new(prop => [23, 42, 99]);
    is_deeply [$obj->prop_all], [23, 42, 99], 'all()';
};

group 'get' => sub {
    my $obj = $class->new(prop => [23, 42, 99]);
    is $obj->prop_get(1), 42, 'get($existing)';
    is $obj->prop_get(12), undef, 'get($unknown)';
    is $obj->prop_get(-1), 99, 'get($negative)';
    is $obj->prop_get0, 23, 'get($curried)';
    is_deeply [$obj->prop_get_all(0, 2)], [23, 99],
        'get_all($index0, $index1)';
    is scalar($obj->prop_get_all(1)), 42,
        'scalar get_all($index)';
    is_deeply [$obj->prop_get01], [23, 42],
        'get_all($curried0, $curried1)';
    is_deeply [$obj->prop_get01(2)], [23, 42, 99],
        'get_all($curried0, $curried1, $other)';
    is_deeply $obj->get_prop, [23, 42, 99], 'nothing changed';
};

group 'set' => sub {
    my $obj = $class->new(prop => [23, 42, 99]);
    my @emitted;
    for my $signal (qw( prop_changed )) {
        $obj->signal_connect($signal, sub {
            my (undef, @args) = @_;
            push @emitted, [$signal, @args];
            return undef;
        });
    }
    is $obj->prop_set(2, 24), 1, 'set($index, $value) return';
    is_deeply $obj->get_prop, [23, 42, 24], 'set($index, $value) after';
    is $obj->prop_set0(17), 1, 'set($curried, $value) return';
    is_deeply $obj->get_prop, [17, 42, 24], 'set($curried, $value) after';
    like exception { $obj->prop_set(17, 23) },
        qr{Invalid index '17'},
        'set($index_too_high, $value)';
    like exception { $obj->prop_set(-1, 23) },
        qr{Invalid index '-1'},
        'set($neg_index, $value)';
    is $obj->prop_set_all(0 => 99, 2 => 98), 1,
        'set_all($index, $value, ...) return';
    is_deeply $obj->get_prop, [99, 42, 98],
        'set_all($index, $value, ...) after';
    is $obj->prop_set_all0(79, 2 => 78), 1,
        'set_all($curried, $value, ...) return';
    is_deeply $obj->get_prop, [79, 42, 78],
        'set_all($curried, $value, ...) after';
    like exception { $obj->prop_set_all(17, 23) },
        qr{Invalid index '17'},
        'set($index_too_high, $value)';
    like exception { $obj->prop_set_all(-1, 23) },
        qr{Invalid index '-1'},
        'set($neg_index, $value)';
    is_deeply \@emitted, [
        ['prop_changed', 2, 24, 99],
        ['prop_changed', 0, 17, 23],
        ['prop_changed', 0, 99, 17],
        ['prop_changed', 2, 98, 24],
        ['prop_changed', 0, 79, 99],
        ['prop_changed', 2, 78, 98],
    ], 'emissions';
};

group 'push/pop' => sub {
    my $obj = $class->new(prop => [23, 42, 99]);
    my @emitted;
    for my $signal (qw( prop_deleted prop_inserted )) {
        $obj->signal_connect($signal, sub {
            my (undef, @args) = @_;
            push @emitted, [$signal, @args];
            return undef;
        });
    }
    group 'pop' => sub {
        is $obj->prop_pop, 99, 'pop()';
        is_deeply $obj->get_prop, [23, 42], 'pop() changes';
        group 'on empty' => sub {
            my $obj = $class->new(prop => [23]);
            my @emitted;
            for my $signal (qw( prop_deleted prop_inserted )) {
                $obj->signal_connect($signal, sub {
                    my (undef, @args) = @_;
                    push @emitted, [$signal, @args];
                    return undef;
                });
            }
            is $obj->prop_pop, 23, 'pop() on last';
            is $obj->prop_pop, undef, "pop() on empty $_"
                for 1 .. 3;
            is_deeply \@emitted, [
                ['prop_deleted', 0, 23],
            ], 'emitted';
        };
    };
    group 'push' => sub {
        is $obj->prop_push(3, 4), 1, 'push($value0, $value1)';
        is_deeply $obj->get_prop, [23, 42, 3, 4],
            'push($value0, $value1) changes';
        is $obj->prop_push0(3, 4), 1, 'push($curried, $value0, $value1)';
        is_deeply $obj->get_prop, [23, 42, 3, 4, 0, 3, 4],
            'push($curried, $value0, $value1) changes';
    };
    is_deeply \@emitted, [
        ['prop_deleted', 2, 99],
        ['prop_inserted', 2, 3],
        ['prop_inserted', 3, 4],
        ['prop_inserted', 4, 0],
        ['prop_inserted', 5, 3],
        ['prop_inserted', 6, 4],
    ], 'emissions';
};

group 'shift/unshift' => sub {
    my $obj = $class->new(prop => [23, 42, 99]);
    my @emitted;
    for my $signal (qw( prop_deleted prop_inserted )) {
        $obj->signal_connect($signal, sub {
            my (undef, @args) = @_;
            push @emitted, [$signal, @args];
            return undef;
        });
    }
    group 'shift' => sub {
        is $obj->prop_shift, 23, 'shift()';
        is_deeply $obj->get_prop, [42, 99], 'shift() changes';
        group 'on empty' => sub {
            my $obj = $class->new(prop => [23]);
            my @emitted;
            for my $signal (qw( prop_deleted prop_inserted )) {
                $obj->signal_connect($signal, sub {
                    my (undef, @args) = @_;
                    push @emitted, [$signal, @args];
                    return undef;
                });
            }
            is $obj->prop_shift, 23, 'shift() on last';
            is $obj->prop_shift, undef, "shift() on empty $_"
                for 1 .. 3;
            is_deeply \@emitted, [
                ['prop_deleted', 0, 23],
            ], 'emitted';
        };
    };
    group 'unshift' => sub {
        is $obj->prop_unshift(3, 4), 1, 'unshift($value0, $value1)';
        is_deeply $obj->get_prop, [3, 4, 42, 99],
            'unshift($value0, $value1) changes';
        is $obj->prop_unshift0(3, 4), 1,
            'unshift($curried, $value0, $value1)';
        is_deeply $obj->get_prop, [0, 3, 4, 3, 4, 42, 99],
            'unshift($curried, $value0, $value1) changes';
    };
    is_deeply \@emitted, [
        ['prop_deleted', 0, 23],
        ['prop_inserted', 0, 4],
        ['prop_inserted', 0, 3],
        ['prop_inserted', 0, 4],
        ['prop_inserted', 0, 3],
        ['prop_inserted', 0, 0],
    ], 'emissions';
};

group 'mapping' => sub {
    my $obj = $class->new(prop => [23, 42, 99]);
    is_deeply [$obj->prop_map(sub { $_ * 2 })], [46, 84, 198],
        'map($code)';
    is_deeply [$obj->prop_map(sub { $_ + $_[1] }, 10)], [33, 52, 109],
        'map($code, $argument)';
    is_deeply [$obj->prop_map_prefix('foo')],
        ['23-foo: 23', '42-foo: 42', '99-foo: 99'],
        'map($curried, $argument)';
};

group 'grepping' => sub {
    my $obj = $class->new(prop => [23, 42, 99]);
    group 'grep' => sub {
        is_deeply [$obj->prop_grep(sub { $_ % 2 })], [23, 99],
            'grep($code)';
        is_deeply [$obj->prop_grep(sub { $_ % $_[1] }, 2)], [23, 99],
            'grep($code, $argument)';
        is_deeply [$obj->prop_grep_mod(2)], [23, 99],
            'grep($curried, $argument)';
        is scalar($obj->prop_grep_mod(2)), 2,
            'scalar grep($curried, $argument)';
    };
    group 'first' => sub {
        is $obj->prop_first(sub { not $_ % 2 }), 42,
            'first($code)';
        is $obj->prop_first(sub { $_ > 1000 }), undef,
            'first($not_finding_code)';
        is $obj->prop_first(sub { not $_ % $_[1] }, 2), 42,
            'first($code, $argument)';
        is $obj->prop_first_nmod(2), 42,
            'first($curried, $argument)';
    };
    group 'first_index' => sub {
        is $obj->prop_ifirst(sub { $_ % 2 }), 0,
            'first_index($code)';
        is $obj->prop_ifirst(sub { $_ > 1000 }), undef,
            'first_index($not_finding_code)';
        is $obj->prop_ifirst(sub { not $_ % $_[1] }, 2), 1,
            'first_index($code, $argument)';
        is $obj->prop_ifirst_mod(2), 0,
            'first_index($curried, $argument)';
    };
};

group 'predicates' => sub {
    my $obj = $class->new(prop => [23, 42, 99]);
    is $obj->prop_exists(2), 1, 'exists($known)';
    is $obj->prop_exists(9), 0, 'exists($unknown)';
    is $obj->prop_exists0, 1, 'exists($curried_known)';
    is $obj->prop_exists20, 0, 'exists($curried_unknown)';
};

group 'constraints' => sub {
    group 'item_isa' => sub {
        my $class = TestProperty(
            type => 'Array',
            is => 'ro',
            item_isa => sub { die "FAIL\n" if ref $_[0] },
            handles => {
                prop_set_all => 'set_all',
                prop_set => 'set',
                prop_get_x => ['get', '1'],
                prop_push => 'push',
                prop_unshift => 'unshift',
            },
        );
        group 'construct' => sub {
            is $class->new(prop => [23, 17, 42])->prop_get_x, 17,
                'correct value';
            like exception { $class->new(prop => [23, {}]) },
                qr{Property 'prop' value error: Index 1: FAIL},
                'wrong value';
        };
        group 'set_all' => sub { 
            my $obj = $class->new(prop => [23, 17, 42]);
            is $obj->prop_set_all(1, 99), 1, 'correct value';
            like exception { $obj->prop_set_all(2 => 23, 0 => []) },
                qr{Property 'prop' index 0 value error: FAIL},
                'wrong value';
            is_deeply $obj->get_prop, [23, 99, 42], 'consistency';
        };
        group 'set' => sub { 
            my $obj = $class->new(prop => [23, 17, 42]);
            is $obj->prop_set(1, 99), 1, 'correct value';
            like exception { $obj->prop_set(1 => []) },
                qr{Property 'prop' index 1 value error: FAIL},
                'wrong value';
            is_deeply $obj->get_prop, [23, 99, 42], 'consistency';
        };
        group 'push' => sub {
            my $obj = $class->new(prop => [23, 17, 42]);
            is $obj->prop_push(11, 12), 1, 'correct value';
            like exception { $obj->prop_push(13, []) },
                qr{Property 'prop' push item 1 value error: FAIL},
                'wrong value';
        };
        group 'unshift' => sub {
            my $obj = $class->new(prop => [23, 17, 42]);
            is $obj->prop_unshift(11, 12), 1, 'correct value';
            like exception { $obj->prop_unshift(13, []) },
                qr{Property 'prop' unshift item 1 value error: FAIL},
                'wrong value';
        };
    };
    group 'item_class' => sub {
        my $class = TestProperty(
            type => 'Array',
            is => 'ro',
            item_class => 'TestObject',
            handles => {
                prop_set_x => ['set', 0],
                prop_get_x => ['get', 0],
            },
        );
        my $ok = bless {}, 'TestObject';
        my $err = bless {}, 'WrongObject';
        group 'construct' => sub {
            is exception { $class->new(prop => [$ok]) },
                undef,
                'correct class';
            like exception { $class->new(prop => [$ok, $err]) },
                qr{Property 'prop' value error: Index 1: Not an instance},
                'wrong class';
        };
        group 'set' => sub { 
            my $obj = $class->new(prop => [$ok]);
            is $obj->prop_set_x($ok), 1, 'correct class';
            like exception { $obj->prop_set_x($err) },
                qr{Property 'prop' index 0 value error: Not an instance},
                'wrong class';
        };
    };
};

group 'coercions' => sub {
    my $class = TestProperty(
        type => 'Array',
        is => 'ro',
        item_coerce => sub {
            die "FAIL\n" if ref $_[0];
            return $_[0] * 2;
        },
        handles => {
            prop_get => 'get',
            prop_set_x => ['set', 0],
            prop_get_x => ['get', 0],
            prop_set_all => 'set_all',
            prop_push => 'push',
            prop_unshift => 'unshift',
        },
    );
    group 'construct' => sub {
        is exception {
            my $obj = $class->new(prop => [23, 17, 42]);
            is $obj->prop_get_x, 46, 'coercion applied';
        }, undef, 'no errors for correct value';
        like exception { $class->new(prop => [23, {}]) },
            qr{Property 'prop' value error: Index 1: FAIL},
            'coercion error';
    };
    group 'set' => sub {
        my $obj = $class->new(prop => [23, 17, 42]);
        is exception {
            is $obj->prop_set_x(17), 1, 'correct value return';
            is $obj->prop_get_x, 34, 'coercion applied';
        }, undef, 'no errors for correct value';
        like exception { $obj->prop_set_x([]) },
            qr{Property 'prop' index 0 value error: FAIL},
            'coercion error';
    };
    group 'set_all' => sub {
        my $obj = $class->new(prop => [23, 17, 42]);
        is exception {
            is $obj->prop_set_all(0 => 22), 1, 'correct value return';
            is $obj->prop_get_x, 44, 'coercion applied';
        }, undef, 'no errors for correct value';
        like exception { $obj->prop_set_all(1 => []) },
            qr{Property 'prop' index 1 value error: FAIL},
            'coercion error';
    };
    group 'push' => sub {
        my $obj = $class->new(prop => [23, 17, 42]);
        is exception {
            is $obj->prop_push(12), 1, 'correct value return';
            is $obj->prop_get(-1), 24, 'coercion applied';
        }, undef, 'no errors for correct value';
        like exception { $obj->prop_push(11, []) },
            qr{Property 'prop' push item 1 value error: FAIL},
            'coercion error';
    };
    group 'unshift' => sub {
        my $obj = $class->new(prop => [23, 17, 42]);
        is exception {
            is $obj->prop_unshift(12), 1, 'correct value return';
            is $obj->prop_get(0), 24, 'coercion applied';
        }, undef, 'no errors for correct value';
        like exception { $obj->prop_unshift(11, []) },
            qr{Property 'prop' unshift item 1 value error: FAIL},
            'coercion error';
    };
};

done_testing;
