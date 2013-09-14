use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;
use Object::Glib::TestProperty;

group 'default isa check' => sub {
    my $class = TestProperty(is => 'ro', type => 'Hash');
    is_deeply $class->new(prop => { x => 23 })->get_prop,
        { x => 23 },
        'valid init argument';
    like exception { $class->new(prop => 23) },
        qr{Property 'prop' value error: Not a hash reference},
        'invalid init argument type';
};

group 'default value' => sub {
    group 'no overrides' => sub {
        my $class = TestProperty(is => 'ro', type => 'Hash');
        is_deeply $class->new->get_prop, {}, 'correct value';
        ok $class->can('_build_prop'), 'builder installed';
    };
    group 'builder override' => sub {
        my $class = TestProperty(
            is => 'ro',
            type => 'Hash',
            builder => sub { { x => 23 } },
        );
        is_deeply $class->new->get_prop, { x => 23 }, 'correct value';
    };
    group 'default override' => sub {
        my $class = TestProperty(
            is => 'ro',
            type => 'Hash',
            default => sub { { x => 23 } },
        );
        is_deeply $class->new->get_prop, { x => 23 }, 'correct value';
    };
};

like exception {
    TestProperty(type => 'Hash', signals => { foo => 1 });
}, qr{Unknown property signals: foo},
    'unknown signals';

my $class = TestProperty(
    type => 'Hash',
    is => 'ro',
    signals => {
        insert => 1,
        update => 1,
        delete => 1,
    },
    handles => {
        prop_keys => 'keys',
        prop_values => 'values',
        prop_kv => 'kv',
        prop_get => 'get',
        prop_get_x => ['get', 'x'],
        prop_get_all => 'get_all',
        prop_get_xy => ['get_all', qw( x y )],
        prop_set => 'set',
        prop_set_x => ['set', 'x'],
        prop_set_all => 'set_all',
        prop_delete => 'delete',
        prop_delete_x => ['delete', 'x'],
        prop_delete_all => 'delete_all',
        prop_delete_xy => ['delete_all', qw( x y )],
        prop_exists => 'exists',
        prop_x_exists => ['exists', 'x'],
        prop_y_exists => ['exists', 'y'],
        prop_defined => 'defined',
        prop_x_defined => ['defined', 'x'],
        prop_y_defined => ['defined', 'y'],
        prop_a_defined => ['defined', 'a'],
        prop_clear => 'clear',
        prop_count => 'count',
        prop_clone => 'shallow_clone',
        prop_map_pairs => 'map_pairs',
        prop_map_joined => ['map_pairs', sub { join ':', @_ }],
        prop_get_req => 'get_required',
        prop_each_value => 'each_value',
    },
);

group 'introspection' => sub {
    my $obj = $class->new(prop => { x => 23, y => 42, a => 99 });
    is_deeply [sort $obj->prop_keys],
        [qw( a x y )],
        'keys()';
    is_deeply [sort $obj->prop_values],
        [23, 42, 99],
        'values()';
    is_deeply [sort { $a->[0] cmp $b->[0] } $obj->prop_kv],
        [['a', 99], ['x', 23], ['y', 42]],
        'kv()';
    is $obj->prop_count, 3, 'count()';
};

group 'mappings' => sub {
    group 'map_pairs' => sub {
        my $obj = $class->new(prop => { x => 23, y => 42 });
        is_deeply [sort $obj->prop_map_pairs(sub { join '.', @_ })],
            ['x.23', 'y.42'],
            'map_pairs($code)';
        is_deeply [sort $obj->prop_map_joined],
            ['x:23', 'y:42'],
            'map_pairs($curried)';
    };
};

group 'iteration' => sub {
    group 'each_value' => sub {
        my $obj = $class->new(prop => { x => 23, y => 42 });
        my @done;
        is $obj->prop_each_value(sub {
            push @done, $_ . '-' . join ':', @_;
        }, 'foo'), 1, 'each_value($code, $arg) return';
        is_deeply [sort @done], ['23-23:foo', '42-42:foo'],
            'each_value($code, $arg) calls';
    };
};

group 'access' => sub {
    group 'get' => sub {
        my $obj = $class->new(prop => { x => 23, y => 42, a => 99 });
        is $obj->prop_get('x'), 23, 'get($key)';
        is $obj->prop_get('z'), undef, 'get($unknown)';
        is $obj->prop_get_x, 23, 'get($curried)';
    };
    group 'get_all' => sub {
        my $obj = $class->new(prop => { x => 23, y => 42, a => 99 });
        is scalar($obj->prop_get_all('x')), 1, 'scalar get_all($key)';
        is_deeply [$obj->prop_get_all(qw( x y ))],
            [23, 42],
            'get_all(@keys)';
        is_deeply [$obj->prop_get_all],
            [],
            'get_all()';
        is_deeply [$obj->prop_get_xy],
            [23, 42],
            'get_all(@curried)';
        is_deeply [$obj->prop_get_xy('a')],
            [23, 42, 99],
            'get_all(@curried, @other)';
    };
    group 'get_required' => sub {
        my $obj = $class->new(prop => { x => 23, y => 42, a => 99 });
        is $obj->prop_get_req('x'), 23, 'with existing key';
        like exception {
            $obj->prop_get_req('foo');
        }, qr{Unknown prop key 'foo'}, 'with non-existing key';
    };
};

group 'get_buildable' => sub {
    my $class = TestProperty(
        type => 'Hash',
        is => 'ro',
        handles => {
            get_value => ['get_buildable', sub {
                my ($self, $key, $arg) = @_;
                $arg ||= 'def';
                return join ':', $self->prefix, $key, $arg;
            }],
        },
        _ => { prefix => sub { 'pre' } },
    );
    my $obj = $class->new(prop => { x => 23 });
    is $obj->get_value('x'), 23, 'existing value';
    is_deeply $obj->get_prop, { x => 23 }, 'no changes';
};

group 'setting' => sub {
    my $obj = $class->new;
    my @emitted;
    for my $signal (qw( prop_inserted prop_changed )) {
        $obj->signal_connect($signal, sub {
            my (undef, @args) = @_;
            push @emitted, [$signal, @args];
            return undef;
        });
    }
    group 'set' => sub {
        is $obj->prop_set(y => 23), 1, 'set($key, $val) return';
        is $obj->prop_get('y'), 23, 'set($key, $val) value';
        is $obj->prop_set_x(42), 1, 'set($curried, $val) return';
        is $obj->prop_get_x, 42, 'set($curried, $val) value';
        is $obj->prop_set_x(43), 1, 'changing set($curried, $val) return';
        is $obj->prop_get_x, 43, 'changing set($curried, $val) value';
        is_deeply \@emitted, [
            ['prop_inserted', 'y', 23],
            ['prop_inserted', 'x', 42],
            ['prop_changed', 'x', 43, 42],
        ], 'emissions';
    };
    @emitted = ();
    group 'set_all' => sub {
        is $obj->prop_set_all(x => 9, a => 10), 1,
            'set_all(%kv) return';
        is_deeply $obj->get_prop,
            { a => 10, x => 9, y => 23 },
            'set_all(%kv) value';
        is_deeply [sort { $a->[1] cmp $b->[1] } @emitted], [
            ['prop_inserted', 'a', 10],
            ['prop_changed', 'x', 9, 43],
        ], 'emissions';
    };
};

group 'delete' => sub {
    my $obj = $class->new;
    my @emitted;
    $obj->signal_connect('prop_deleted', sub {
        my (undef, @args) = @_;
        push @emitted, [@args];
        return undef;
    });
    $obj->prop_set_all(x => 23, y => 17, z => 42, a => 99, b => 98);
    is $obj->prop_delete('z'), 42, 'prop_delete($key)';
    is $obj->prop_delete_x, 23, 'prop_delete($curried)';
    is_deeply [sort $obj->prop_keys], [qw( a b y )], 'keys left';
    is_deeply \@emitted, [
        ['z', 42],
        ['x', 23],
    ], 'single delete emissions';
    @emitted = ();
    $obj->prop_set_all(x => 23, y => 17, z => 42, a => 99, b => 98);
    is_deeply [$obj->prop_delete_all('a', 'b')],
        [99, 98],
        'delete_all(@keys)';
    is_deeply [sort $obj->prop_keys], [qw( x y z )], 'keys left';
    $obj->prop_set_all(x => 23, y => 17, z => 42, a => 99, b => 98);
    is_deeply [$obj->prop_delete_xy('z')],
        [23, 17, 42],
        'delete_all(@curried, @other)';
    is_deeply [sort $obj->prop_keys], [qw( a b )], 'keys left';
    is_deeply \@emitted, [
        ['a', 99],
        ['b', 98],
        ['x', 23],
        ['y', 17],
        ['z', 42],
    ], 'multi delete emissions';
};

group 'predicates' => sub {
    group 'exists' => sub {
        my $obj = $class->new(prop => { x => 23, z => undef });
        ok $obj->prop_exists('x'), 'exists($known)';
        ok !$obj->prop_exists('y'), 'exists($unknown)';
        ok $obj->prop_exists('z'), 'exists($undefined)';
        ok $obj->prop_x_exists, 'exists($curried_known)';
        ok !$obj->prop_y_exists, 'exists($curried_unknown)';
    };
    group 'defined' => sub {
        my $obj = $class->new(prop => { x => 23, z => undef });
        ok $obj->prop_defined('x'), 'defined($known)';
        ok !$obj->prop_defined('y'), 'defined($unknown)';
        ok !$obj->prop_defined('z'), 'defined($undefined)';
        ok $obj->prop_x_defined, 'defined($curried_known)';
        ok !$obj->prop_y_defined, 'defined($curried_unknown)';
        ok !$obj->prop_a_defined, 'defined($curried_undefined)';
    };
};

group 'clear' => sub {
    my $obj = $class->new;
    my @emitted;
    $obj->signal_connect('prop_deleted', sub {
        my (undef, @args) = @_;
        push @emitted, [@args];
        return undef;
    });
    $obj->prop_set_all(x => 23, y => 17);
    is $obj->prop_clear, 1, 'clear()';
    is_deeply $obj->get_prop, {}, 'hash now empty';
    is_deeply [sort { $a->[0] cmp $b->[0] } @emitted], [
        ['x', 23],
        ['y', 17],
    ], 'emissions';
};

group 'clone' => sub {
    my $obj = $class->new(prop => { x => 23, y => 17 });
    my $clone = $obj->prop_clone;
    $clone->{a} = 99;
    is_deeply $obj->get_prop, { x => 23, y => 17 }, 'shallow_clone()';
};

group 'constraints' => sub {
    group 'item_isa' => sub {
        my $class = TestProperty(
            type => 'Hash',
            is => 'ro',
            item_isa => sub { die "FAIL\n" if ref $_[0] },
            handles => {
                prop_set_all => 'set_all',
                prop_set => 'set',
                prop_get_x => ['get', 'x'],
            },
        );
        group 'construct' => sub {
            is $class->new(prop => { x => 23 })->prop_get_x, 23,
                'correct value';
            like exception { $class->new(prop => { x => [] }) },
                qr{Property 'prop' value error: Item 'x': FAIL},
                'wrong value';
        };
        group 'set_all' => sub { 
            my $obj = $class->new;
            is $obj->prop_set_all('x', 23), 1, 'correct value';
            like exception { $obj->prop_set_all(x => 17, y => []) },
                qr{Property 'prop' item 'y' value error: FAIL},
                'wrong value';
            is_deeply $obj->get_prop, { x => 23 }, 'consistency';
        };
        group 'set' => sub { 
            my $obj = $class->new;
            is $obj->prop_set('x', 23), 1, 'correct value';
            like exception { $obj->prop_set(y => []) },
                qr{Property 'prop' item 'y' value error: FAIL},
                'wrong value';
            is_deeply $obj->get_prop, { x => 23 }, 'consistency';
        };
    };
    group 'item_class' => sub {
        my $class = TestProperty(
            type => 'Hash',
            is => 'ro',
            item_class => 'TestObject',
            handles => {
                prop_set_x => ['set', 'x'],
                prop_get_x => ['get', 'x'],
            },
        );
        my $ok = bless {}, 'TestObject';
        my $err = bless {}, 'WrongObject';
        group 'construct' => sub {
            is exception { $class->new(prop => { x => $ok }) },
                undef,
                'correct class';
            like exception { $class->new(prop => { x => $err }) },
                qr{Property 'prop' value error: Item 'x': Not an instance},
                'wrong class';
        };
        group 'set' => sub { 
            my $obj = $class->new;
            is $obj->prop_set_x($ok), 1, 'correct class';
            like exception { $obj->prop_set_x($err) },
                qr{Property 'prop' item 'x' value error: Not an instance},
                'wrong class';
        };
    };
};

group 'coercions' => sub {
    my $class = TestProperty(
        type => 'Hash',
        is => 'ro',
        item_coerce => sub {
            die "FAIL\n" if ref $_[0];
            return $_[0] * 2;
        },
        handles => {
            prop_set_x => ['set', 'x'],
            prop_get_x => ['get', 'x'],
            prop_set_all => 'set_all',
        },
    );
    group 'construct' => sub {
        is exception {
            my $obj = $class->new(prop => { x => 23 });
            is $obj->prop_get_x, 46, 'coercion applied';
        }, undef, 'no errors for correct value';
        like exception { $class->new(prop => { x => [] }) },
            qr{Property 'prop' value error: Item 'x': FAIL},
            'coercion error';
    };
    group 'set' => sub {
        my $obj = $class->new;
        is exception {
            is $obj->prop_set_x(17), 1, 'correct value return';
            is $obj->prop_get_x, 34, 'coercion applied';
        }, undef, 'no errors for correct value';
        like exception { $obj->prop_set_x([]) },
            qr{Property 'prop' item 'x' value error: FAIL},
            'coercion error';
    };
    group 'set_all' => sub {
        my $obj = $class->new;
        is exception {
            is $obj->prop_set_all(x => 17), 1, 'correct value return';
            is $obj->prop_get_x, 34, 'coercion applied';
        }, undef, 'no errors for correct value';
        like exception { $obj->prop_set_all(x => []) },
            qr{Property 'prop' item 'x' value error: FAIL},
            'coercion error';
    };
};

done_testing;
