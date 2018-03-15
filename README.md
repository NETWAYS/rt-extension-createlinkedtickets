# CreateLinkedTickets Extension for Request Tracker

#### Table of Contents

1. [About](#about)
2. [License](#license)
3. [Support](#support)
4. [Requirements](#requirements)
5. [Installation](#installation)
6. [Configuration](#configuration)

## About

Provides automatic creation of linked tickets.

## License

This project is licensed under the terms of
the GNU General Public License Version 2, Copyright held by author.

## Support

For bugs and feature requests please head over to our
[issue tracker](https://github.com/NETWAYS/rt-extension-createlinkedtickets/issues).
You may also send us an email to [support@netways.de](mailto:support@netways.de)
for general questions or to get technical support.

## Requirements

- RT 4.4.2
- [RT::Extension::TicketActions](https://github.com/NETWAYS/rt-extension-ticketactions)
  (for rendering Font Awesome icons)

## Installation

Extract this extension to a temporary location.

Git clone:

```
cd /usr/local/src
git clone https://github.com/NETWAYS/rt-extension-createlinkedtickets
```

Tarball download (latest [release](https://github.com/NETWAYS/rt-extension-createlinkedtickets/releases/latest)):

```
cd /usr/local/src
wget https://github.com/NETWAYS/rt-extension-createlinkedtickets/archive/v1.0.0.zip
unzip v1.0.0.zip
```

Navigate into the source directory and install the extension.

```
perl Makefile.PL
make
make install
```

Clear your mason cache.

```
rm -rf /opt/rt4/var/mason_data/obj
```

Restart your web server.

```
systemctl restart httpd

systemctl restart apache2
```

## Configuration

```
Set($RTx_CreateLinkedTickets_Config, [
    {
        name     => 'clt-billing',    # internal name used
        title    => 'Billing Ticket', # title which is visible in frontend
        template => 'CLT-Billing',    # template for RT::Action::CreateTickets (<ID>|<NAME>)
        icon     => 'cart-plus',      # Font Awesome icon to use
    }
]);
```

### Template

```
===Create-Ticket: billing-ticket
Subject: Billing: {$Tickets{'TOP'}->Subject}
Refers-To: {$Tickets{'TOP'}->Id}
Queue: TESTQUEUENAME
CustomField-client: {$Tickets{'TOP'}->FirstCustomFieldValue('client')}
Content: Billing ticket for Ticket #{$Tickets{'TOP'}->Id} ({$Tickets{'TOP'}->Subject}) created.
ENDOFCONTENT
```
