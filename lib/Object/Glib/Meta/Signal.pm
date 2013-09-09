use strictures 1;

package Object::Glib::Meta::Signal;
use Moo;
use Object::Glib::Types qw( :ident :ref :val :oo );

use namespace::clean;

has recurse => (is => 'ro', default => sub { 1 });
has detailed => (is => 'ro', default => sub { 0 });
has hooks => (is => 'ro', default => sub { 1 });

has returns => (
    is => 'ro',
    isa => \&isa_class,
);

has name => (
    is => 'ro',
    isa => \&isa_ident,
    required => 1,
);

my %_valid_mode = (
    first => 1,
    last => 1,
    cleanup => 1,
);

has mode => (
    is => 'ro',
    lazy => 1,
    init_arg => 'run',
    isa => sub {
        die sprintf "Signal run mode must be one of %s\n",
            join ', ', keys %_valid_mode,
            unless defined $_[0] and $_valid_mode{ $_[0] };
    },
    builder => sub {
        my ($self) = @_;
        return 'last'
            if defined $self->returns;
        return 'first';
    },
);

has params => (
    is => 'ro',
    isa => \&isa_array,
    lazy => 1,
    builder => sub {
        my ($self) = @_;
        my $arity = $self->arity;
        return []
            unless $arity;
        return [('Glib::Scalar') x $arity];
    },
);

has arity => (
    is => 'ro',
    isa => \&isa_int_pos0,
);

has perform => (
    is => 'ro',
    isa => \&isa_code,
    lazy => 1,
    builder => sub { sub { undef } },
);

sub install_into {
    my ($self, $meta) = @_;
    return 1;
}

sub glib {
    my ($self) = @_;
    return {
        flags => [
            sprintf('run-%s', $self->mode),
            not($self->recurse)
                ? ('no-recurse')
                : (),
            $self->detailed
                ? ('detailed')
                : (),
            not($self->hooks)
                ? ('no-hooks')
                : (),
        ],
        param_types => $self->params,
        class_closure => $self->perform,
        defined($self->returns)
            ? (return_type => $self->returns)
            : (),
    };
}

1;
