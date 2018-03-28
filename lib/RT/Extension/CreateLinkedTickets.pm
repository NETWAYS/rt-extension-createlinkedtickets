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

A simple extension that works with RT 4.4.2 which provides automatic creation of
linked tickets.

=head1 RT VERSION

Works with RT 4.4.2

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

=head2 C<$CreateLinkedTickets_Config>

    Set($CreateLinkedTickets_Config, [
        {
            name     => 'clt-billing',    # internal name used
            title    => 'Billing Ticket', # title which is visible in frontend
            template => 'CLT-Billing',    # template for RT::Action::CreateTickets (<ID>|<NAME>)
            icon     => 'cart-plus',      # Font Awesome icon to use
        }
    ]);

=head1 AUTHOR

NETWAYS GmbH L<support@netways.de|mailto:support@netways.de>

=head1 BUGS

All bugs should be reported at L<GitHub|https://github.com/NETWAYS/rt-extension-createlinkedtickets/issues>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2018 by NETWAYS GmbH

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
