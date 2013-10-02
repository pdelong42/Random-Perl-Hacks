#!/usr/bin/perl

use strict;
use warnings;

my $fh;
my $CPUs = 0;

open( $fh, '/proc/uptime' )
   or die "unable to read /proc/uptime - aborting\n";

my( $up, $idle ) = split ' ', readline( $fh );

open( $fh, '/proc/stat' )
   or die "unable to read /proc/stat - aborting\n";

foreach( readline $fh ) {
   ++$CPUs if m/^cpu\d+/;
}

my $pctidle = 100 * $idle / $up / $CPUs;
my $days = $idle / 86400;

printf "idle %.3f%% of %d days\n", $pctidle, $days;
