## no critic (RequireUseStrict)
package Dist::Zilla::Plugin::LocalBrew;

## use critic (RequireUseStrict)
use Moose;

extends 'Dist::Zilla::Plugin::Test::LocalBrew';

before register_component => sub {
    warn "!!! [LocalBrew] is deprecated and may be removed in a future release; replace it with [Test::LocalBrew]\n";
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS

=cut
