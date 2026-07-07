package RT::Extension::CreateLinkedTickets;

use 5.26.3;
use strict;
use warnings;
use RT;
use RT::Queue;
use RT::Action::CreateTickets;
use RT::Extension::CreateLinkedTickets::TransientTemplate;

our $VERSION='3.0.0';

RT->AddStyleSheets('createlinkedtickets.css');

=head2 Config

Returns the validated C<$CreateLinkedTickets_Config> entries as an arrayref.
Entries missing a required C<id>/C<name>/C<content>, entries with a
duplicate C<id>, or entries whose C<queue> is not an arrayref of names/ids
that all resolve to a real queue are logged via C<< RT->Logger->warning >>
and skipped.

=cut

sub Config {
    my $raw = RT->Config->Get('CreateLinkedTickets_Config');
    return [] unless ref($raw) eq 'ARRAY';

    my %seen;
    my @entries;

    ENTRY: for my $entry (@$raw) {
        unless ( ref($entry) eq 'HASH' ) {
            RT->Logger->warning('CreateLinkedTickets: skipping config entry: not a hashref');
            next ENTRY;
        }

        my ($id, $name, $content) = @{$entry}{qw(id name content)};
        unless ( defined $id && length $id && defined $name && length $name
            && defined $content && length $content )
        {
            RT->Logger->warning("CreateLinkedTickets: skipping config entry: missing required key 'id', 'name' or 'content'");
            next ENTRY;
        }

        if ( $seen{$id}++ ) {
            RT->Logger->warning("CreateLinkedTickets: skipping config entry: duplicate id '$id'");
            next ENTRY;
        }

        my $queue = $entry->{queue};
        if ( defined $queue ) {
            unless ( ref($queue) eq 'ARRAY' ) {
                RT->Logger->warning("CreateLinkedTickets: skipping config entry '$id': 'queue' must be an arrayref");
                next ENTRY;
            }

            my @resolved;
            for my $value (@$queue) {
                my $q = RT::Queue->new( RT->SystemUser );
                $q->Load($value);
                unless ( $q->id ) {
                    RT->Logger->warning("CreateLinkedTickets: skipping config entry '$id': unknown queue '$value'");
                    next ENTRY;
                }
                push @resolved, $q->id;
            }
            $queue = \@resolved;
        }

        push @entries, {
            id          => $id,
            name        => $name,
            description => $entry->{description} // '',
            queue       => $queue,
            content     => $content,
        };
    }

    return \@entries;
}

=head2 QueueMatches $entry, $ticket

Returns true if C<$entry> has no C<queue> restriction, or if C<$ticket>'s
queue id is one of the entry's (already resolved) C<queue> ids.

=cut

sub QueueMatches {
    my ($entry, $ticket) = @_;
    return 1 unless $entry->{queue};

    my $queue_id = $ticket->Queue;
    return 0 unless defined $queue_id;
    return scalar grep { $_ == $queue_id } @{ $entry->{queue} };
}

=head2 VisibleEntries $ticket

Returns the arrayref of config entries whose queue condition matches
C<$ticket>, for use by the UI.

=cut

sub VisibleEntries {
    my ($ticket) = @_;
    return [ grep { QueueMatches( $_, $ticket ) } @{ Config() } ];
}

=head2 CreateTicketByConfiguration Ticket => $ticket, Id => $id

Creates a new ticket linked to C<Ticket> using the config entry C<Id>. The
entry's C<content> is used as the C<RT::Action::CreateTickets> template text
directly, via a transient in-memory template object -- no admin-managed
Template database row is needed.

Returns C<($ok, $message)>.

=cut

sub CreateTicketByConfiguration {
    my %args = (
        Ticket => undef,
        Id     => undef,
        @_,
    );

    my $ticket = $args{Ticket};
    my $user   = $ticket->CurrentUser;

    my ($entry) = grep { $_->{id} eq ( $args{Id} // '' ) } @{ Config() };
    return ( 0, $user->loc( 'No such linked-ticket action: [_1]', $args{Id} // '' ) )
        unless $entry;

    return ( 0, $user->loc( '"[_1]" is not available for this queue', $entry->{name} ) )
        unless QueueMatches( $entry, $ticket );

    # Transient template. RT::Action::_Init weakens its TemplateObj slot, so
    # this lexical must stay alive until after Commit.
    my $template = RT::Extension::CreateLinkedTickets::TransientTemplate->new(
        Content => $entry->{content},
    );

    my $action = RT::Action::CreateTickets->new(
        CurrentUser => $user,
        TemplateObj => $template,
        TicketObj   => $ticket,
    );

    # Prepare/Commit both unconditionally return true in RT core -- real
    # failures (bad queue, missing rights, a Text::Template die) are only
    # logged internally and skipped. The one failure this DOES reliably
    # catch is a content typo that fails to parse into any Create-Ticket
    # block at all, which is the most common admin-config mistake.
    return ( 0, $user->loc('Could not prepare the ticket-creation action, see the RT log for details') )
        unless $action->Prepare && @{ $action->{create_tickets} || [] };

    return ( 0, $user->loc('Could not create the linked ticket, see the RT log for details') )
        unless $action->Commit;

    return ( 1, $user->loc( 'Linked ticket created ([_1]). See the Links box to verify.', $entry->{name} ) );
}

=pod

=head1 NAME

RT::Extension::CreateLinkedTickets

=head1 DESCRIPTION

Allows to quickly create linked tickets based on templates.

The extension adds a "Create linked tickets" quick action right below the
"Links" box in a ticket's overview: a select box of configured linked-ticket
types plus a "Create ticket" button. In order to avoid ticket creation noise
(notifications to queue watchers) in the workflow, ticket creation must be
confirmed.

=head1 RT VERSION

Works with RT 6.0.0

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::CreateLinkedTickets');

=item Clear your mason cache

    rm -rf /opt/rt/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

The only configuration option required by this extension is C<$CreateLinkedTickets_Config>.
This is a list of hashes, each representing a linked-ticket type to offer. No
admin-managed Template object is needed -- the C<RT::Action::CreateTickets>
template text lives directly in C<content>.

    Set($CreateLinkedTickets_Config, [
        {
            id          => 'billing',                 # Required, unique. Used to reference this entry.
            name        => 'Billing Ticket',          # Required. Display label in the select box.
            description => 'Creates a billing ticket linked to this one.',  # Optional. Tooltip/help text.
            queue       => ['Support', 'Sales'],       # Optional. Arrayref of queue names or ids.
                                                        # Only shown on tickets in a matching queue.
                                                        # Omit to show for every queue.
            content     => <<'ENDOFTEMPLATE',          # Required. RT::Action::CreateTickets template text.
===Create-Ticket: billing-ticket
Subject: Billing: {$Tickets{'TOP'}->Subject}
Refers-To: {$Tickets{'TOP'}->Id}
Queue: Finance
Content: Billing ticket for Ticket #{$Tickets{'TOP'}->Id} ({$Tickets{'TOP'}->Subject}) created.
ENDOFCONTENT
ENDOFTEMPLATE
        },
    ]);

For more information on how to write the template text, see
L<RT::Action::CreateTickets|https://docs.bestpractical.com/rt/6.0/RT/Action/CreateTickets.html>.

=head2 Upgrading from 2.x

Version 3.0.0 requires RT 6 and replaces the config shape entirely: C<icon>
and C<title> are gone, C<template> (a template I<name>) is replaced by
C<content> (the template I<text> itself), and entries gained C<id> and
C<description>. Old-shape entries are skipped with a logged warning rather
than misbehaving. Your previously admin-managed Templates are no longer used
and may be deleted once their C<Content> has been copied into C<content>.

=head1 AUTHOR

NETWAYS GmbH <support@netways.de>

=head1 BUGS

All bugs should be reported on L<GitHub|https://github.com/NETWAYS/rt-extension-createlinkedtickets>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2018-2026 by NETWAYS GmbH

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
