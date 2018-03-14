This extension provide auto creation of linked tickets.

Requires [RT-Extension-TicketActions](https://github.com/NETWAYS/rt-extension-ticketactions)
for rendering Font Awesome icons.

Just install as common and create a following configuration:

    Set($RTx_CreateLinkedTickets_Config, [
        {
            name     => 'clt-billing',    # internal name used
            title    => 'Billing Ticket', # title which is visible in frontend
            template => 'CLT-Billing',    # template for RT::Action::CreateTickets (<ID>|<NAME>)
            icon     => 'cart-plus',      # Font Awesome icon to use
        }
    ]);

A template could look like this:

    ===Create-Ticket: billing-ticket
    Subject: Billing: {$Tickets{'TOP'}->Subject}
    Refers-To: {$Tickets{'TOP'}->Id}
    Queue: TESTQUEUENAME
    CustomField-client: {$Tickets{'TOP'}->FirstCustomFieldValue('client')}
    Content: Billing ticket for Ticket #{$Tickets{'TOP'}->Id} ({$Tickets{'TOP'}->Subject}) created.
    ENDOFCONTENT
