#!/usr/bin/perl

use strict;
use warnings;

use English '-no_match_vars';

my $total = 0;
my @lines;

foreach( readline STDIN ) {
   my @tmp = split;
   my $num = shift @tmp;
   push @lines, [ $num, @tmp ];
   $total += $num;
}

foreach( @lines ) {

   my @tmp = @$ARG;
   my $percent = int( 100 * shift( @tmp ) / $total );
   
   print "$percent @tmp\n";
}
