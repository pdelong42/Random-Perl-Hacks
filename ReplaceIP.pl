#!/usr/bin/perl

=pod

This prints its standard-input right to its standard-output, but replacing any
IP address it finds with any hostname it finds by doing a reverse lookup.  It
leaves the IP address intact if it has no PTR record.

ToDo:

 - re-use the results of lookups for an IP address that occurs more than once
across multiple lines;

=cut

use strict;
use warnings;

use Socket;
use English '-no_match_vars';

foreach( readline STDIN ) {

   my %IPs;

   while( m{ ( \d+ \. \d+ \. \d+ \. \d+ ) }gcx ) {
      ++$IPs{ $1 };
   }

   foreach my $IP ( keys %IPs ) {

      my( $name, $aliases, $addrtype, $length, @addrs )
         = gethostbyaddr( inet_aton( $IP ), AF_INET );

      my $replacement = $IP;

      $replacement = $name
         if defined $name;

      $replacement .= " ($aliases)"
         if $aliases;

      s{ $IP }{ $replacement }x;
   }

   print;
}
