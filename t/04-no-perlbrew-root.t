use strict;
use warnings;
use lib 'lib';

use TAP::Harness;
use Test::More;
use Test::DZil;

my $perlbrew;
unless($perlbrew = $ENV{'TEST_PERLBREW'}) {
    plan skip_all => 'Please define TEST_PERLBREW for this test';
    exit 0;
}

plan tests => 1;
delete $ENV{'PERLBREW_ROOT'};

my $tzil = Builder->from_config(
    { dist_root => 'fake-distributions/Fake' },
    { add_files => {
        'source/dist.ini' => simple_ini({
            name    => 'Fake',
            version => '0.01',
        }, 'GatherDir', 'FakeRelease', 'MakeMaker', 'Manifest',
            [ Prereqs => {
                'IO::String' => 0,
            }],
            [ LocalBrew => {
                brews => $perlbrew,
            }],
        ),
      },
    },
);

$tzil->build;

my $tempdir       = $tzil->tempdir;
my $builddir      = $tempdir->subdir('build');
my $expected_file = $builddir->subdir('xt')->subdir('release')->file("localbrew-$perlbrew.t");

chdir $builddir;

my $tap = TAP::Harness->new({
    verbosity => -3,
    merge     => 1,
});

my $agg = $tap->runtests($expected_file . '');
is $agg->get_status, 'NOTESTS', 'running the test without PERLBREW_ROOT should skip tests';
