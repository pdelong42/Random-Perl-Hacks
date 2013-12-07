#!/usr/bin/perl

use strict;
use warnings;

use File::Find;
use English qw( -no_match_vars );

my $wanted = sub {

   return unless m{ ( .* ) \- ( .{11} ) \. ( webm | mp4 | flv ) }x;

   my $ID = $2;
   my @output = qx( ~/Stuff/bin/youtube-dl -s --get-filename http://www.youtube.com/watch?v=$ID 2> /dev/null );

   if( $? < 0 ) {
      print "ERROR: [$ID] failed to execute: $!\n";
      return;
   }

   if( $? & 127 ) {
      printf "ERROR: [$ID] child died with signal %d, %s coredump\n",
           ( $? & 127 ),  ( $? & 128 ) ? 'with' : 'without';
      return;
   }

   my $rc = $? >> 8;

   unless( $rc == 0 ) {
      printf "ERROR: [$ID] child exited with value $rc\n";
      return;
   }

   my $new = shift @output;

   chomp $new;

   warn "WARNING: [$ID] expected only one line of output, but caught more"
      if( scalar( @output ) > 0 );

   #print "DEBUG: $ID [$3] $1\n";
   #print "DEBUG: $ID $File::Find::fullname\n";
   print "DEBUG: $ID $new\n";
};

push @ARGV, '.'
   unless @ARGV;

find { wanted => $wanted, follow => 1 }, @ARGV;
