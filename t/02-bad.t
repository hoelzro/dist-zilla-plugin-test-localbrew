use strict;
use warnings;
use lib 'lib';

use Cwd qw(getcwd);
use TAP::Harness;
use Test::More;
use Test::DZil;

my $perlbrew;
unless($perlbrew = $ENV{'TEST_PERLBREW'}) {
    plan skip_all => 'Please define TEST_PERLBREW for this test';
    exit 0;
}
plan tests => 6;

sub run_tests {
    my ( $plugin ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $tzil = Builder->from_config(
        { dist_root => 'fake-distributions/Fake' },
        { add_files => {
            'source/dist.ini' => simple_ini({
                name    => 'Fake',
                version => '0.01',
            }, 'GatherDir', 'FakeRelease', 'MakeMaker', 'Manifest',
                [ $plugin => {
                    brews => $perlbrew,
                }],
            ),
          },
        },
    );

    my $tempdir       = $tzil->tempdir;
    my $builddir      = $tempdir->subdir('build');
    my $expected_file = $builddir->subdir('xt')->subdir('release')->file("localbrew-$perlbrew.t");

    $tzil->build;

    ok -e $expected_file, 'test created';
    chdir $builddir;

    my $tap = TAP::Harness->new({
        verbosity => -3,
        merge     => 1,
    });

    my $agg = $tap->runtests($expected_file . '');
    ok $agg->failed, 'running the test should fail';
    isnt $agg->get_status, 'NOTESTS', 'running the test shouldn\'t skip anything';
}

my $wd = getcwd;

run_tests 'LocalBrew';
chdir $wd;
run_tests 'Test::LocalBrew';
