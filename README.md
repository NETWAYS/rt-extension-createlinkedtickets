# Create Linked Tickets Extension for Request Tracker

#### Table of Contents

1. [About](#about)
2. [License](#license)
3. [Support](#support)
4. [Requirements](#requirements)
5. [Installation](#installation)
6. [Configuration](#configuration)

## About

Allows to quickly create linked tickets based on templates.

The extension adds a "Create linked tickets" quick action right below the "Links" box in a ticket's
overview: a select box of configured linked-ticket types plus a "Create ticket" button. An entry can be
restricted to specific queues, in which case it's only shown on tickets in a matching queue.

In order to avoid ticket creation noise (notifications to queue watchers) in the workflow, ticket creation
must be confirmed.

## License

This project is licensed under the terms of the GNU General Public License Version 2.

This software is Copyright (c) 2018 by NETWAYS GmbH [support@netways.de](mailto:support@netways.de).

## Support

For bugs and feature requests please head over to our [issue tracker](https://github.com/NETWAYS/rt-extension-createlinkedtickets/issues).
You may also send us an email to [support@netways.de](mailto:support@netways.de) for general questions or to get technical support.

## Requirements

- RT 6.0.0

## Installation

Extract this extension to a temporary location.

Git clone:

    cd /usr/local/src
    git clone https://github.com/NETWAYS/rt-extension-createlinkedtickets

Tarball download (latest [release](https://github.com/NETWAYS/rt-extension-createlinkedtickets/releases/latest)):

    cd /usr/local/src
    wget https://github.com/NETWAYS/rt-extension-createlinkedtickets/archive/master.zip
    unzip master.zip

Navigate into the source directory and install the extension.

    perl Makefile.PL
    make
    make install

Edit your `/opt/rt/etc/RT_SiteConfig.pm`

Add this line:

    Plugin('RT::Extension::CreateLinkedTickets');

Clear your mason cache:

    rm -rf /opt/rt/var/mason_data/obj

Restart your webserver.

## Configuration

The only configuration option required by this extension is `$CreateLinkedTickets_Config`.
This is a list of hashes, each representing a linked-ticket type to offer. No admin-managed Template
object is needed -- the [RT::Action::CreateTickets](https://docs.bestpractical.com/rt/6.0/RT/Action/CreateTickets.html)
template text lives directly in `content`.

```perl
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
```

For more information on how to write the template text, see
[RT::Action::CreateTickets](https://docs.bestpractical.com/rt/6.0/RT/Action/CreateTickets.html).

### Upgrading from 2.x

Version 3.0.0 requires RT 6 and replaces the config shape entirely: `icon` and `title` are gone,
`template` (a template *name*) is replaced by `content` (the template *text* itself), and entries gained
`id` and `description`. Old-shape entries are skipped with a logged warning rather than misbehaving. Your
previously admin-managed Templates are no longer used and may be deleted once their `Content` has been
copied into `content`.
