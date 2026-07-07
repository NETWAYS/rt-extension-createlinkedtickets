package RT::Extension::CreateLinkedTickets::TransientTemplate;

use 5.26.3;
use strict;
use warnings;

=head1 NAME

RT::Extension::CreateLinkedTickets::TransientTemplate

=head1 DESCRIPTION

A minimal stand-in for L<RT::Template> that satisfies exactly what
C<< RT::Action::CreateTickets->Prepare >> needs (C<id>/C<Type>/C<Content>)
without going through L<RT::Record>/L<DBIx::SearchBuilder>. A real (but
never persisted) C<RT::Template> doesn't work here: C<DBIx::SearchBuilder::Record>'s
C<__Value> only returns an in-memory value set via C<__Set> once the field
has been "fetched" from the database, which never happens for a row with no
C<id> -- C<__Value> falls through to its primary-key-gated DB lookup and
returns C<undef> instead of the value C<__Set> wrote into memory.

=head2 new Content => $text

=head2 id

=head2 Type

=head2 Content

=cut

sub new {
    my ($class, %args) = @_;
    return bless { content => $args{Content} }, $class;
}
sub id      { 0 }
sub Type    { 'Perl' }
sub Content { return $_[0]->{content} }

1;
