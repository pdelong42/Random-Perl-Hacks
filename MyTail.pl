#!/usr/bin/perl

use strict;
use warnings;

use POSIX qw( fmod );
use English qw( -no_match_vars );
use Getopt::Long qw( :config no_ignore_case );
use Time::HiRes qw( gettimeofday tv_interval sleep );

my $hand;
my $counter = 0;

my $MaxCount = 25;
my $InputFile = '/var/log/messages';
my $IntervalIdeal = 1;

my $Header = 'new log lines in the past interval';

GetOptions(

   'filename=s'  => \$InputFile,
   'header=s'    => \$MaxCount,
   'timediff=s'  => \$IntervalIdeal,

) or die "getopts error";

open( $hand, $InputFile )
   or die "unable to open $InputFile";

my $Previous;
my $Elapsed = 0;
my $Interval = $IntervalIdeal;
my $Time0 = [ gettimeofday ];

#$Time0->[1] = 0;

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
   my $linecount = 0;

   ++$linecount foreach readline $hand;

   printf( "%21.6f %23.6f %d\n", $Elapsed, $Delta, $linecount );

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
