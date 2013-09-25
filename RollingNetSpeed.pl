#!/usr/bin/perl

=pod

This was intended to be a quick-and-dirty means of calculating the bitrate of
data currently being transmitted and received through the network interface of
interest, using the statistics provided by the Linux kernel in /proc.  It is a
command-line utility which mimics the style of vmstat/iostat/etc.  I freely
acknowledge that there are better and more robust ways of doing this (most of
which probably use something like RRDtool to do the heavy lifting).  But this
is fine if you're in a hurry and don't need anything fancy.

=cut

use strict;
use warnings;

use POSIX qw( fmod );
use English qw( -no_match_vars );
use Getopt::Long qw( :config no_ignore_case );
use Time::HiRes qw( gettimeofday tv_interval sleep );

my $hand;
my $counter = 0;

my $MaxCount = 25;
my $Interface = 'eth0';
my $InputFile = '/proc/net/dev';
my $IntervalIdeal  = 1;

my $Header = join ' | ',
   'total elapsed seconds',
   'delta elapsed seconds',
   '   received bps',
   '    average bps',
   'transmitted bps',
   '    average bps';

sub Rate {

   my $tmp = shift;

   $tmp -= shift;
   $tmp *= 8;
   $tmp /= shift;

   return $tmp;
}

sub PollFile {

   seek( $hand, 0, 0 )
      or warn "could not seek back to the beginning of the file\n";

   foreach( readline $hand ) {

      next unless m{
         ^
         \s* $Interface
         \s* \:
         \s* ( \d+ ) (?: \s+ \d+ ){7}
         \s+ ( \d+ ) (?: \s+ \d+ ){7}
      }x;

      return( $1, $2 );
   }
}

GetOptions(

   'filename=s'  => \$InputFile,
   'header=s'    => \$MaxCount,
   'interface=s' => \$Interface,
   'timediff=s'  => \$IntervalIdeal,

) or die "getopts error";

open( $hand, $InputFile )
   or die "unable to open $InputFile";

my $Previous;
my $Elapsed = 0;
my $Interval = $IntervalIdeal;
my $Time0 = [ gettimeofday ];

my( $rx0,   $tx0   ) = PollFile();
my( $rxOld, $txOld ) = ( $rx0, $tx0 );

++$OUTPUT_AUTOFLUSH;

do {

   if( $MaxCount > 0 ) {

      print "$Header\n"
         if( $counter == 0 );

      ++$counter;
      $counter %= $MaxCount;
   }

   sleep $Interval;

   $Previous = $Elapsed;
   $Elapsed = tv_interval $Time0;
   $Interval = $IntervalIdeal - fmod( $Elapsed, $IntervalIdeal );

   my $Delta = $Elapsed - $Previous;

   my( $rx, $tx ) = PollFile();

   printf(
      "%21.6f %23.6f %17.3f %17.3f %17.3f %17.3f\n",
      $Elapsed, $Delta,
      Rate( $rx, $rxOld, $Delta ), Rate( $rx, $rx0, $Elapsed ),
      Rate( $tx, $txOld, $Delta ), Rate( $tx, $tx0, $Elapsed ),
   );

   ( $rxOld, $txOld ) = ( $rx, $tx );

} until undef;

=pod

ToDo:

 - The above logic, for ensuring that the average polling interval stays as
close to the ideal as possible, is somewhat kludgy.  A better way of doing this
would be to make use of some system-provided service for registering a callback
for a periodic clock interrupt (e.g., wake-up and do stuff whenever the clock
tick interrupt says a second has passed).  This is assuming such a facility
exists (which it may not).

 - Correct for counter wraps.  Currently I don't intend to run this script long
enough to worry about such a condition.  Famous last words...

=cut
