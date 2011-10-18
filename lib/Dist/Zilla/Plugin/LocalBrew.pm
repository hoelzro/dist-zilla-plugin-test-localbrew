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

# ABSTRACT: DEPRECATED - Use Test::LocalBrew instead

=head1 SYNOPSIS

This module is deprecated; please use L<Dist::Zilla::Plugin::Test::LocalBrew>
instead.

=cut
