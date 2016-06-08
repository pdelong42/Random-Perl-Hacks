#!/usr/bin/perl

use strict;
use warnings;

use English '-no_match_vars';

my %NamesToPIDs;

foreach my $filename ( glob "/proc/[0123456789]*/stat" ) {

   my( $hand, $name, $PID );

   unless( open $hand, $filename ) {
      warn "unable to open $filename - skipping\n";
      next;
   }

   foreach( readline $hand ) {

      next unless m/^\s*(\S+)\s+\(([^)]*)\)/;

      $PID  = $1;
      $name = $2;

      warn "PID sanity check failed\n"
         unless "/proc/${PID}/stat" eq $filename;
   }

   push @{ $NamesToPIDs{ $name } }, $PID;
}

foreach( keys %NamesToPIDs ) {
   printf "%d x %s\n", scalar( @{ $NamesToPIDs{ $ARG } } ), $ARG;
}

=pod
foreach( readline STDIN ) {
   
}
=cut
