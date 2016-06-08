#!/usr/bin/perl

use strict;
use warnings;

use English '-no_match_vars';
use Data::Dumper

$Data::Dumper::Indent   = 1;
$Data::Dumper::Sortkeys = 1;

my( %PIDsToPaths, %PathsToPIDs, %PIDsToNames, %NamesToPIDs );

foreach my $filename ( glob "/proc/[0123456789]*/maps" ) {

   my $hand;

   unless( open $hand, $filename ) {
      warn "unable to open $filename - skipping\n";
      next;
   }

   my( $PID ) = $filename =~ m{ ^ /proc/(\d+)/maps $ }x;

   foreach( readline $hand ) {

      my( $address, $perms, $offset, $dev, $inode, $pathname ) = split;

      next unless defined $pathname;

      ++$PathsToPIDs{ $pathname }{ $PID };
      ++$PIDsToPaths{ $PID }{ $pathname };
   }
}

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

   ++$PIDsToNames{ $PID }{ $name };
   ++$NamesToPIDs{ $name }{ $PID };
}

sub PrintJoinedHashes {

   my( $hashref1, $hashref3 ) = @_;

   foreach my $column1 ( sort keys %$hashref1 ) {

      my $hashref2 = $hashref1->{ $column1 };

      foreach my $column2 ( sort keys %$hashref2 ) {

         my $hashref4 = $hashref3->{ $column2 };

         foreach my $column3 ( sort keys %$hashref4 ) {

            printf "$column1 $column2 $column3\n";
         }
      }
   }
}

PrintJoinedHashes \%NamesToPIDs, \%PIDsToPaths;

printf "\n";

PrintJoinedHashes \%PathsToPIDs, \%PIDsToNames;

=pod

foreach( keys %NamesToPIDs ) {
   printf "%d x %s\n", scalar( @{ $NamesToPIDs{ $ARG } } ), $ARG;
}

foreach( readline STDIN ) {
   
}
=cut
