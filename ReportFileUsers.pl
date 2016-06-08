#!/usr/bin/perl

use strict;
use warnings;

use English '-no_match_vars';
use Data::Dumper

$Data::Dumper::Indent = 1;

my( %NamesToPIDs, %PathsToPIDs );

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

   push @{ $NamesToPIDs{ $name } }, $PID;
}

print Dumper \%PathsToPIDs;

=pod
foreach( keys %NamesToPIDs ) {
   printf "%d x %s\n", scalar( @{ $NamesToPIDs{ $ARG } } ), $ARG;
}

foreach( readline STDIN ) {
   
}
=cut
