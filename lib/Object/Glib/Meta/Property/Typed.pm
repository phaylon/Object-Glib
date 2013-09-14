use strictures 1;

package Object::Glib::Meta::Property::Typed;
use Carp qw( croak );
use Object::Glib::Types qw( :ref :ident );
use Object::Glib::CarpGroup;
use Moo::Role;

use namespace::clean;

requires qw(
    _build_typed_builder
    _build_signal_formats
    _install_delegation_method
);

has signal_formats => (
    is => 'ro',
    init_arg => undef,
    builder => 1,
);

has handles => (
    is => 'ro',
    isa => \&isa_hash_or_array,
    default => sub { {} },
);

has signals => (
    is => 'ro',
    isa => \&isa_hash,
    default => sub { {} },
);

has signal_base => (
    is => 'ro',
    isa => \&isa_ident,
    lazy => 1,
    builder => sub { $_[0]->name },
);

around _build_builder => sub {
    my ($orig, $self) = @_;
    my $value = $self->$orig;
    $value = $self->_build_typed_builder
        if not($value) and not(defined $self->default);
    return $value;
};

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
    croak qq{Invalid signal name '$value'}
        unless is_ident($value);
    return $value;
}

sub _install_delegations_into {
    my ($self, $meta) = @_;
    my $handles = $self->handles;
    if (ref $handles eq 'ARRAY') {
        $handles = { (map { ($_, $_) } @$handles) };
    }
    for my $as (keys %$handles) {
        my $target = $handles->{ $as };
        my ($method, @curry);
        if (ref $target eq 'ARRAY') {
            croak join ' ',
                q{Curried delegation needs to contain at least},
                q{the name of the target method},
                unless @$target;
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
        croak q{Invalid delegation method name}
            unless is_ident($as);
        croak q{Invalid delegation target name}
            unless is_ident($method);
        $self->_install_delegation_method($meta, $as, $method, @curry);
    }
    return 1;
}

1;
