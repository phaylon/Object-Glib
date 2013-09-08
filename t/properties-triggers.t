use strictures 1;
use Test::More;
use Test::Fatal;
use FindBin;
use lib "$FindBin::Bin/lib";
use Object::Glib::Test;
use Object::Glib::TestProperty;

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
