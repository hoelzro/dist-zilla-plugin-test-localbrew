use strict;
use warnings;

use Cwd qw(getcwd);
use TAP::Harness;
use Test::More;
use Test::DZil;

sub run_tests {
    my ( $perlbrew, $plugin ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $wd = getcwd;

    do { # try a bad distribution without notest_deps
        my $tzil = Builder->from_config(
            { dist_root => 'fake-distributions/RequiresBadFake' },
            { add_files => {
                'source/dist.ini' => simple_ini({
                    name    => 'RequiresBadFake',
                    version => '0.01',
                }, 'GatherDir', 'FakeRelease', 'MakeMaker', 'Manifest',
                    [ Prereqs => {
                        'BadFake' => 0,
                    }],
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

        chdir $builddir;
        my $tap = TAP::Harness->new({
            verbosity => -3,
            merge     => 1,
        });

        my $agg = $tap->runtests($expected_file . '');
        ok $agg->failed, 'running the test should fail';
        isnt $agg->get_status, 'NOTESTS', 'running the test shouldn\'t skip anything';
    };

    chdir $wd;

    do { # try a bad distribution with notest_deps
        my $tzil = Builder->from_config(
            { dist_root => 'fake-distributions/RequiresBadFake' },
            { add_files => {
                'source/dist.ini' => simple_ini({
                    name    => 'RequiresBadFake',
                    version => '0.01',
                }, 'GatherDir', 'FakeRelease', 'MakeMaker', 'Manifest',
                    [ Prereqs => {
                        'BadFake' => 0,
                    }],
                    [ $plugin => {
                        notest_deps => 1,
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

        chdir $builddir;
        my $tap = TAP::Harness->new({
            verbosity => -3,
            merge     => 1,
        });

        my $agg = $tap->runtests($expected_file . '');
        ok !$agg->failed, 'running the test should succeed';
        isnt $agg->get_status, 'NOTESTS', 'running the test shouldn\'t skip anything';
    };

    chdir $wd;

    do { # try a distribution with failing tests to make sure we actually test things
        my $tzil = Builder->from_config(
            { dist_root => 'fake-distributions/Fake' },
            { add_files => {
                'source/dist.ini' => simple_ini({
                    name    => 'Fake',
                    version => '0.01',
                }, 'GatherDir', 'FakeRelease', 'MakeMaker', 'Manifest',
                    [ $plugin => {
                        notest_deps => 1,
                        brews       => $perlbrew,
                    }],
                ),
              },
            },
        );

        my $tempdir       = $tzil->tempdir;
        my $builddir      = $tempdir->subdir('build');
        my $expected_file = $builddir->subdir('xt')->subdir('release')->file("localbrew-$perlbrew.t");

        $tzil->build;

        chdir $builddir;

        my $tap = TAP::Harness->new({
            verbosity => -3,
            merge     => 1,
        });

        my $agg = $tap->runtests($expected_file . '');
        ok $agg->failed, 'running the test should fail';
        isnt $agg->get_status, 'NOTESTS', 'running the test shouldn\'t skip anything';
    };

    chdir $wd;
}

my $perlbrew;
unless($perlbrew = $ENV{'TEST_PERLBREW'}) {
    plan skip_all => 'Please define TEST_PERLBREW for this test';
    exit 0;
}

plan tests => 12;

my $wd = getcwd;

$ENV{'PERL_CPANM_OPT'} = "--mirror-only --mirror file:///$wd/fake-cpan/";
run_tests $perlbrew, 'LocalBrew';
run_tests $perlbrew, 'Test::LocalBrew';
