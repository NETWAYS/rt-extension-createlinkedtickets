use inc::Module::Install;

RTx     'RT-Extension-CreateLinkedTickets';
license 'gpl_2';
repository 'https://github.com/NETWAYS/rt-extension-createlinkedtickets';
readme_from 'lib/RT/Extension/CreateLinkedTickets.pm';

requires_rt '4.4.2';

sign;
WriteAll;
