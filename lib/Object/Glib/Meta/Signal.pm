use strictures 1;

package Object::Glib::Meta::Signal;
use Moo;

use namespace::clean;

has name => (is => 'ro', required => 1);
has mode => (is => 'ro', builder => 1, lazy => 1, init_arg => 'run');
has recurse => (is => 'ro', default => sub { 1 });
has detailed => (is => 'ro', default => sub { 0 });
has hooks => (is => 'ro', default => sub { 1 });
has params => (is => 'ro', builder => 1, lazy => 1);
has arity => (is => 'ro');
has perform => (is => 'ro', builder => 1, lazy => 1);
has returns => (is => 'ro');

sub _build_perform { sub { undef } }

sub _build_mode {
    my ($self) = @_;
    return 'last'
        if defined $self->returns;
    return 'first';
}

sub _build_params {
    my ($self) = @_;
    my $arity = $self->arity;
    return []
        unless $arity;
    return [('Glib::Scalar') x $arity];
}

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
