## no critic (RequireUseStrict)
package Dist::Zilla::Plugin::Test::LocalBrew;

use File::Spec;
use File::Temp qw(tempdir);

use namespace::clean;

## use critic (RequireUseStrict)
use Moose;
with 'Dist::Zilla::Role::FileGatherer', 'Dist::Zilla::Role::TextTemplate';

has brews => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

sub mvp_multivalue_args {
    qw/brews/
}

my $template = <<'TEMPLATE';
#!perl

use strict;
use warnings;

use FindBin;
use File::Spec;
use File::Temp;
use Test::More;

unless($ENV{'PERLBREW_ROOT'}) {
    plan skip_all => "Environment variable 'PERLBREW_ROOT' not found";
    exit;
}

my $cpanm_path = qx(which cpanm 2>/dev/null);
unless($cpanm_path) {
    plan skip_all => "The 'cpanm' program is required to run this test";
    exit;
}
chomp $cpanm_path;

my $perlbrew_bin = File::Spec->catdir($ENV{'PERLBREW_ROOT'}, 'perls',
    "{{$brew}}", 'bin');

unless(-x File::Spec->catfile($perlbrew_bin, 'perl')) {
    plan skip_all => "No such perlbrew environment '{{$brew}}'";
    exit;
}

my $env = do {
    local $ENV{'SHELL'} = '/bin/bash'; # fool perlbrew
    qx(perlbrew env {{$brew}})
};

my @lines = split /\n/, $env;

foreach my $line (@lines) {
    if($line =~ /^\s*export\s+([0-9a-zA-Z_]+)=(.*)$/) {
        my ( $k, $v ) = ( $1, $2 );
        if($v =~ /^("|')(.*)\1$/) {
            $v = $2;
            $v =~ s!\\(.)!$1!ge;
        }
        $ENV{$k} = $v;
    } elsif($line =~ /^unset\s+([0-9a-zA-Z_]+)/) {
        delete $ENV{$1};
    }
}

$ENV{'PATH'} = join(':', @ENV{qw/PERLBREW_PATH PATH_WITHOUT_PERLBREW/});

plan tests => 1;

my $tmpdir = File::Temp->newdir;

my $pid = fork;
if($pid) {
    unless(defined $pid) {
        fail "Forking failed!";
        exit 1;
    }
    waitpid $pid, 0;
    ok !$?, "cpanm should successfully install your dist with no issues";
} else {
    close STDOUT;
    close STDERR;

    chdir File::Spec->catdir($FindBin::Bin,
        File::Spec->updir, File::Spec->updir); # exit test directory

    exec 'perl', $cpanm_path, '-L', $tmpdir->dirname, '.';
}
TEMPLATE

sub gather_files {
    my ( $self ) = @_;

    my $brews = $self->brews;

    unless(@$brews) {
        $self->log_fatal('No perlbrew environments specified in your dist.ini');
    }

    foreach my $brew (@$brews) {
        $self->add_file(Dist::Zilla::File::InMemory->new(
            name    => "xt/release/localbrew-$brew.t",
            content => $self->fill_in_string($template, {
                brew => $brew,
            }),
        ));
    }
}

no Moose;
1;

__END__

# ABSTRACT: Verify that your distribution tests well in a fresh perlbrew

=head1 SYNOPSIS

  # in your dist.ini
  [Test::LocalBrew]
  brews = first-perlbrew
  brews = second-perlbrew

=head1 DESCRIPTION

This plugin builds and tests your module with a set of given perlbrew
environments before a release and aborts the release if testing in any
of them fails.  Any dependencies are installed via cpanminus into
a temporary local lib, so your perlbrew environments aren't altered.
This comes in handy when you want to build against a set of "fresh" Perl
installations (ie. those with only core modules) to make sure all of your
prerequisites are included correctly.

=head1 ATTRIBUTES

=head2 brews

A list of perlbrew environments to build and test in.

=head1 ISSUES

=over

=item Relies on the 'which' program to detect cpanm.

=back

=head1 SEE ALSO

L<Dist::Zilla>, L<App::perlbrew>, L<App::cpanminus>, L<local::lib>

=cut
