package RT::Extension::CreateLinkedTickets;

use version;

our $VERSION="1.0.0";

use strict;

use Data::Dumper;
use RT::Action::CreateTickets;

use vars qw (
	$config
);

$config = RT->Config->Get('CreateLinkedTickets_Config') // [];

use subs qw {
	createLinkedTicket
	getConfigurationByName
};

RT->AddStyleSheets('createlinkedtickets.css');

sub getConfigurationByName {
	my $name = shift;
	my @items = grep { $_->{'name'} eq $name } @{$config};
	if (scalar(@items) eq 1) {
		return shift @items;
	}
}

sub createTicketByConfiguration {
	my $a = {
		Ticket	=> undef,
		Config	=> undef,
		User	=> undef,
		@_
	};

	my $c = getConfigurationByName($a->{'Config'});

	return (undef, "Could not load config for \"$a->{'Config'}\"") unless (ref($c) eq 'HASH');

	my $Ticket = $a->{'Ticket'};
	my $User = $a->{'User'};
	my $msg = undef;

	$User = $Ticket->CurrentUser unless($User);

	my $Template = RT::Template->new($User);
	$Template->Load($c->{'template'});

	if (!$Template->Id) {
		return (undef, 'Could not load template'. ': '. $c->{'template'}, undef);
	}

	my $Transaction = RT::Transaction->new(
		Type			=> 'CreateLinkedTicket',
		ObjectType 		=> ref($Ticket),
		ObjectId		=> $Ticket->Id
	);

	my $Action = RT::Action::CreateTickets->new(
		CurrentUser	=> $User,
		TemplateObj	=> $Template,
		TicketObj	=> $Ticket
	);

	unless ($Action->Prepare()) {
		return (undef, 'Could not prepare action', undef);
	}

	unless ($Action->Commit()) {
		return (undef, 'Could not commit action', undef);
	}

	return (1, 'Linked ticket created. Please see links section to validate.');
}

=pod

=head1 NAME

RT::Extension::CreateLinkedTickets

=head1 DESCRIPTION

Allows to quickly create linked tickets based on templates.

The extension adds configurable quick actions right under the "Links" widget in a ticket's overview.

In order to avoid ticket creation noise (notifications to queue watchers) in the workflow, ticket creation
must be confirmed.

=head1 RT VERSION

Works with RT 4.4.2

=head1 REQUIREMENTS

=over

=item RT::Extension::TicketActions (>= 1.0.1)

Provides "Font Awesome" icon integration.

=back

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::CreateLinkedTickets');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

The only configuration option required by this extension is C<$CreateLinkedTickets_Config>.
This is a list of hashes each representing a quick action to show.

    Set($CreateLinkedTickets_Config, [
        {
            name     => 'clt-billing',    # Internal name used
            icon     => 'cart-plus',      # Font Awesome icon to use for the action
            title    => 'Billing Ticket', # Title which is visible in the action's tooltip
            template => 'CLT-Billing',    # Template for RT::Action::CreateTickets (<ID>|<NAME>)
        },
    ]);

Additionally each of those hashes needs to reference a template that is passed to
L<RT::Action::CreateTickets|https://docs.bestpractical.com/rt/4/RT/Action/CreateTickets.html>.

For more information on how to write templates please refer to the official documentation linked above.

=head2 Template Example

Please note that this is a very basic example and should generally work. The only thing you need to adjust
is the given C<Queue> so that it's valid one.

	===Create-Ticket: billing-ticket
	Subject: Billing: {$Tickets{'TOP'}->Subject}
	Refers-To: {$Tickets{'TOP'}->Id}
	Queue: Finance
	Content: Billing ticket for Ticket #{$Tickets{'TOP'}->Id} ({$Tickets{'TOP'}->Subject}) created.
	ENDOFCONTENT

Just create this template by navigating to "Admin -> Global -> Templates -> Create", select C<Perl> as type
and give it C<CLT-Billing> as name and you're good to go.

=head1 AUTHOR

NETWAYS GmbH <support@netways.de>

=head1 BUGS

All bugs should be reported on L<GitHub|https://github.com/NETWAYS/rt-extension-createlinkedtickets>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2018 by NETWAYS GmbH

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
