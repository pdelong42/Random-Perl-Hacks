#!/usr/bin/perl

use strict;
use warnings;

use Socket;
use English;

my @lists;

sub FirstColumn { sprintf "%-15s ", inet_ntoa( shift() ) }

foreach( @ARGV ) {

   my @tmp = split '/';
   my $max = 2 ** ( 32 - $tmp[1] ) - 1;
   my $net = unpack( 'N', inet_aton( $tmp[0] ) );
   my $list = "${ARG}:\n";

   foreach( 0..$max ) {

      my $naddr = pack 'N', $net | $ARG;

      my( $name, $aliases, $addrtype, $length, @addrs ) = gethostbyaddr $naddr, AF_INET;

      unless( @addrs ) {
         $list .= FirstColumn( $naddr ) . "NXDOMAIN\n";
         next;
      }

      my $line = join ' ', map { FirstColumn $ARG } @addrs;

      $line .= $name           if $name;
      $line .= " (${aliases})" if $aliases;

      $list .= "$line\n";
   }

   push @lists, $list;
}

print join( "\n", @lists );
