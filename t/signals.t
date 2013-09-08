use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;
use Object::Glib::TestSignal;

group 'emission' => sub {
    my $class = TestSignal();
    my $obj = $class->new;
    my $n = 0;
    $obj->signal_connect('foo', sub { $n++; undef });
    $obj->signal_emit('foo');
    is $n, 1, 'signal was emitted';
};

my @_calls;
my @_run_first_tests = (
    ['default', TestSignal(perform => sub {
        push @_calls, 'perform';
        return undef;
    })],
    ['explicit', TestSignal(run => 'first', perform => sub {
        push @_calls, 'perform';
        return undef;
    })],
);

for my $test (@_run_first_tests) {
    my ($detail, $class) = @$test;
    @_calls = ();
    group "run first ($detail)" => sub {
        my $obj = $class->new;
        $obj->signal_connect('foo', sub {
            push @_calls, 'connect';
            return undef;
        });
        $obj->signal_connect_after('foo', sub {
            push @_calls, 'connect_after';
            return undef;
        });
        $obj->signal_emit('foo');
        is_deeply \@_calls, ['perform', 'connect', 'connect_after'],
            'calls';
    };
}

my @_run_last_tests = (
    ['explicit', TestSignal(run => 'last', perform => sub {
        push @_calls, 'perform';
        return undef;
    })],
    ['by return', TestSignal(returns => 'Glib::Scalar', perform => sub {
        push @_calls, 'perform';
        return 23;
    })],
);

for my $test (@_run_last_tests) {
    my ($detail, $class) = @$test;
    @_calls = ();
    group "run last ($detail)" => sub {
        my $obj = $class->new;
        $obj->signal_connect('foo', sub {
            push @_calls, 'connect';
            return undef;
        });
        $obj->signal_connect_after('foo', sub {
            push @_calls, 'connect_after';
            return undef;
        });
        $obj->signal_emit('foo');
        is_deeply \@_calls, ['connect', 'perform', 'connect_after'],
            'calls';
    };
}

group 'run cleanup' => sub {
    my $class = TestSignal(run => 'cleanup', perform => sub {
        push @_calls, 'perform';
        return undef;
    });
    @_calls = ();
    my $obj = $class->new;
    $obj->signal_connect('foo', sub {
        push @_calls, 'connect';
        return undef;
    });
    $obj->signal_connect_after('foo', sub {
        push @_calls, 'connect_after';
        return undef;
    });
    $obj->signal_emit('foo');
    is_deeply \@_calls, ['connect', 'connect_after', 'perform'],
        'calls';
};

group 'params' => sub {
    my $class = TestSignal(params => ['Glib::Scalar'], perform => sub {
        my (undef, $val) = @_;
        push @_calls, $val;
        return undef;
    });
    @_calls = ();
    my $obj = $class->new;
    $obj->signal_emit('foo', 23);
    is_deeply \@_calls, [23], 'parameter value';
};

group 'arity' => sub {
    my $class = TestSignal(arity => 2, perform => sub {
        my (undef, @vals) = @_;
        push @_calls, [@vals];
        return undef;
    });
    @_calls = ();
    my $obj = $class->new;
    $obj->signal_emit('foo', 23, 42);
    is_deeply \@_calls, [[23, 42]], 'parameter value';
};

group 'returns' => sub {
    my $class = TestSignal(
        arity => 1,
        returns => 'Glib::Scalar',
        perform => sub {
            my (undef, $val) = @_;
            push @_calls, ['perform', $val];
            return $val * 2;
        },
    );
    @_calls = ();
    my $obj = $class->new;
    is $obj->signal_emit('foo', 23), 46, 'returned value';
    $obj->signal_connect('foo', sub {
        my (undef, $val) = @_;
        push @_calls, ['connect', $val];
        return $val x 2;
    });
    is $obj->signal_emit('foo', 42), 84, 'handler return value';
    is_deeply \@_calls, [
        ['perform', 23],
        ['connect', 42],
        ['perform', 42],
    ], 'calls';
};

done_testing;
