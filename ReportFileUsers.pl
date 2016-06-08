#!/usr/bin/perl

use strict;
use warnings;

use English '-no_match_vars';
use Data::Dumper

$Data::Dumper::Indent   = 1;
$Data::Dumper::Sortkeys = 1;

my $ProcDir = "/proc/[0123456789]*";

my( %PIDsToPaths, %PathsToPIDs, %PIDsToNames, %NamesToPIDs );

my @paths = readline STDIN;

chomp @paths;

foreach my $filename ( glob "${ProcDir}/maps" ) {

   my $hand;

   unless( open $hand, $filename ) {
      warn "unable to open $filename - skipping\n";
      next;
   }

   my( $PID ) = $filename =~ m{ ^ /proc/(\d+)/maps $ }x;

   foreach( readline $hand ) {

      my( $address, $perms, $offset, $dev, $inode, $pathname ) = split;

      next unless $pathname;

      next if( @paths and not grep { $pathname eq $ARG } @paths );

      ++$PathsToPIDs{ $pathname }{ $PID };
      ++$PIDsToPaths{ $PID }{ $pathname };
   }
}

foreach my $filename ( glob "${ProcDir}/stat" ) {

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
