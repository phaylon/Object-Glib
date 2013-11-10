use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %_deps_runtime = (
    'aliased' => 0,
    'Class::ISA' => '0.36',
    'Class::Method::Modifiers' => '2.04',
    'Data::Dump' => 0,
    'Glib' => '1.300',
    'Gtk2' => 0,
    'Import::Into' => 0,
    'List::MoreUtils' => 0,
    'Module::Runtime' => 0,
    'Moo' => '1.003',
    'namespace::clean' => 0,
    'Package::Stash' => '0.34',
    'Package::Variant' => 0,
    'parent' => 0,
    'Role::Tiny' => 0,
    'Safe::Isa' => 0,
    'strictures' => 0,
    'Sub::Install' => 0,
    'Try::Tiny' => '0.18',
);

my %_deps_tests = (
    'Test::Fatal' => 0,
    'Test::More' => 0,
);

WriteMakefile(
  NAME => 'Object::Glib',
  VERSION_FROM => 'lib/Object/Glib.pm',
  PREREQ_PM => { %_deps_runtime },
  BUILD_REQUIRES => { %_deps_tests },
  LICENSE => 'perl',
);
