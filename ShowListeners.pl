#!/usr/bin/perl

=pod

Just a quick-and-dirty script to print a succinct list of TCP ports in LISTEN
state.  Since it relies on specifics of /proc, it only works on Linux.

=cut

use strict;
use warnings;

use English qw( -no_match_vars );

my %foo;

foreach( glob '/proc/net/tcp*' ) {

   my $hand;

   unless( open $hand, $ARG ) {
      print "skipping $ARG - unable to open\n";
      next;
   }

   foreach( readline $hand ) {

      my @tmp = split;

      next unless $tmp[3] eq '0A';

      my( $address, $port ) = split ':', $tmp[1];

      $foo{ $port } = $tmp[7];
   }
}

printf "port (UID)\n";
printf( "%d (%s)\n", hex(), $foo{ $ARG } )
   foreach sort keys %foo;
