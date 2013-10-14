#!/usr/bin/perl

=pod

Just a quick-and-dirty script to print what fraction of the time the host has
been idle, and how many days it's been up.  Not sure how useful this is past my
one instance of needing it.  Since it relies on specifics of /proc, it only
works on Linux.

=cut

use strict;
use warnings;

my $hand;
my $CPUs = 0;

open( $hand, '/proc/uptime' )
   or die "unable to read /proc/uptime - aborting\n";

my( $up, $idle ) = split ' ', readline( $hand );

open( $hand, '/proc/stat' )
   or die "unable to read /proc/stat - aborting\n";

foreach( readline $hand ) {
   ++$CPUs if m/^cpu\d+/;
}

my $pctidle = 100 * $idle / $up / $CPUs;
my $days = $idle / 86400;

printf "idle %.3f%% of %d days\n", $pctidle, $days;
