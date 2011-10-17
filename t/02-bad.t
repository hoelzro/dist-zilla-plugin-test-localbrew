use strict;
use warnings;
use lib 'lib';

use Test::More;
use Test::DZil;
use Test::Exception;

my $perlbrew;
unless($perlbrew = $ENV{'TEST_PERLBREW'}) {
    plan skip_all => 'Please define TEST_PERLBREW for this test';
    exit 0;
}
plan tests => 1;

my $tzil = Builder->from_config(
    { dist_root => 'fake-distributions/Fake' },
    { add_files => {
        'source/dist.ini' => simple_ini({
            name    => 'Fake',
            version => '0.01',
        }, 'GatherDir', 'FakeRelease', 'ModuleBuild', 'Manifest',
            [ LocalBrew => {
                brews => $perlbrew,
            }],
        ),
      },
    },
);

throws_ok {
    $tzil->release;
} qr/failed in perlbrew environment/;
