use strict;
use warnings;

use Test::Exception;
use Test::More tests => 1;
use Test::DZil;

my $tzil = Builder->from_config(
    { dist_root => 'fake-distributions/Fake' },
    { add_files => {
        'source/dist.ini' => simple_ini({
            name    => 'Fake',
            version => '0.01',
        }, 'GatherDir', 'FakeRelease', 'ModuleBuild', 'Manifest',
            [ Prereqs => {
                'IO::String' => 0,
            }],
            [ LocalBrew => {
            }],
        ),
      },
    },
);

throws_ok {
    $tzil->release;
} qr/No perlbrew environments specified/;
