use strictures 1;

package Object::Glib::Exporter;
use Sub::Install qw( reinstall_sub install_sub );
use Try::Tiny;
use Object::Glib::Registry qw( register_meta );
use Object::Glib::CarpGroup;

use namespace::clean;
use Exporter 'import';

our @EXPORT = qw(
    setup_exports
);

my $_export = sub {
    my ($meta, $sub, $code) = @_;
    reinstall_sub {
        into => $meta->package,
        as => $sub,
        code => sub {
            my @args = @_;
            my ($line, $file) = (caller)[2, 1];
            try {
                $code->($meta, @args);
            }
            catch {
                my $err = $_;
                chomp $err;
                $err .= sprintf ' at %s line %d.',
                        $file, $line
                    unless $err =~ m{line\d+\.?$}xi;
                die "$err\n";
            };
            return 1;
        },
    };
};

sub setup_exports {
    my %arg = @_;
    my $target = caller;
    install_sub {
        into => $target,
        as => 'import',
        code => sub {
            my $package = caller;
            my $meta = $arg{meta_class}->new(package => $package);
            register_meta($meta);
            for my $sub (@{ $arg{export} || [] }) {
                my $code = $target->can("_proto_$sub");
                $_export->($meta, $sub, $code);
            }
            $arg{finalize}->($package);
            for my $sub (@{ $arg{override_after} || [] }) {
                my $code = $target->can("_proto_$sub");
                $_export->($meta, $sub, $code);
            }
            return 1;
        },
    };
}

1;
