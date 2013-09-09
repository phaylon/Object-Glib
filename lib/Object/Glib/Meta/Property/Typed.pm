use strictures 1;

package Object::Glib::Meta::Property::Typed;
use Carp qw( croak );
use Moo::Role;

use namespace::clean;

requires qw(
    _build_typed_builder
    _build_signal_formats
    _install_delegation_method
);

our @CARP_NOT = qw(
    Object::Glib
    Object::Glib::Meta::Class
);

has handles => (is => 'ro', default => sub { {} });
has signals => (is => 'ro', default => sub { {} });
has signal_base => (is => 'ro', builder => 1, lazy => 1);
has signal_formats => (is => 'ro', init_arg => undef, builder => 1);

around _build_builder => sub {
    my ($orig, $self) = @_;
    my $value = $self->$orig;
    $value = $self->_build_typed_builder
        if not($value) and not(defined $self->default);
    return $value;
};

sub _build_signal_base { $_[0]->name }

after install_into => sub {
    my ($self, $meta) = @_;
    $self->_install_delegations_into($meta);
};

sub _check_property_signals {
    my ($self) = @_;
    my $formats = $self->signal_formats;
    my $signals = $self->signals;
    my @unknown = grep { not exists $formats->{ $_ } } keys %$signals;
    croak sprintf q{Unknown property signals: %s},
        join ', ', @unknown,
        if @unknown;
    return 1;
}

sub _signal_name {
    my ($self, $id) = @_;
    return undef
        unless exists $self->signals->{ $id };
    my $value = $self->signals->{ $id };
    $value = sprintf $self->signal_formats->{ $id }, $self->signal_base
        if $value eq 1;
    return $value;
}

sub _install_delegations_into {
    my ($self, $meta) = @_;
    my $handles = $self->handles;
    if (ref $handles eq 'ARRAY') {
        $handles = { (map { ($_, $_) } @$handles) };
    }
    croak join ' ',
        q{Property 'handles' attribute needs to be},
        q{array or hash reference},
        unless ref $handles eq 'HASH';
    for my $as (keys %$handles) {
        my $target = $handles->{ $as };
        my ($method, @curry);
        if (ref $target eq 'ARRAY') {
            ($method, @curry) = @$target;
        }
        elsif (not ref $target and defined $target) {
            $method = $target;
        }
        else {
            croak join ' ',
                q{Delegation target needs to be string},
                q{or array reference};
        }
        $self->_install_delegation_method($meta, $as, $method, @curry);
    }
    return 1;
}

1;
