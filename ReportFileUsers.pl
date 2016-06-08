#!/usr/bin/perl

use strict;
use warnings;

use English '-no_match_vars';

my %NamesToPIDs;

foreach my $filename ( glob "/proc/*/status" ) {

   my( $hand, $name, $PID );

   unless( open $hand, $filename ) {
      warn "unable to open $filename - skipping\n";
      next;
   }

   foreach( readline $hand ) {

      if( m/^Name\s*:\s*(.*)/ ) {
         $name = $1;
         next;
      }

      if( m/^Pid:\s*:\s*(.*)/ ) {

         $PID = $1;

         warn "PID sanity check failed\n"
            unless "/proc/${PID}/status" eq $filename;

         next;
      }
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
