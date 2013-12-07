#!/usr/bin/perl

use strict;
use warnings;

use File::Copy;
use File::Find;
use File::Path qw( make_path );
use English qw( -no_match_vars );

my $wanted = sub {

   return unless m{ ( .* ) \- ( .{11} ) \. ( webm | mp4 | flv ) }x;

   my $ID = $2;
   my $old = $File::Find::fullname;
   my @output = qx( ~/Stuff/bin/youtube-dl -s --get-filename http://www.youtube.com/watch?v=$ID 2> /dev/null );

   warn "DEBUG: [$ID] $old\n";

   if( $? < 0 ) {
      warn "ERROR: [$ID] failed to execute: $!\n";
      return;
   }

   if( $? & 127 ) {
      warn "ERROR: [$ID] child died with signal %d, %s coredump\n",
           ( $? & 127 ),  ( $? & 128 ) ? 'with' : 'without';
      return;
   }

   my $rc = $? >> 8;

   unless( $rc == 0 ) {
      warn "ERROR: [$ID] child exited with value $rc\n";
      return;
   }

   my $new = shift @output;

   chomp $new;

   my @tmp = split '/', $new;

   pop @tmp;

   my $dir = join '/', @tmp;

   make_path $dir;

   unless( -d $dir ) {
      warn "ERROR: [$ID] unable to create directory $dir\n";
      return;
   }

   warn "WARNING: [$ID] expected only one line of output, but caught more\n"
      if( scalar( @output ) > 0 );

   if( -f $new ) {
      warn qq(WARNING: [$ID] destination already exists - skipping "$new"\n);
      return;
   }

   unless( copy $old, $new ) {
      warn qq(ERROR: [$ID] unable to copy "$old" to "$new"\n);
      return;
   }

   print qq(created: $new\n);

#   if( unlink( $old ) > 0 ) {
#      print qq(moved "$old" to "$new"\n);
#   } else {
#      warn qq(ERROR: [$ID] unable to remove "$old"\n);
#      print qq(copied "$old" to "$new"\n);
#   }
#
};

push @ARGV, '.'
   unless @ARGV;

find { wanted => $wanted, follow => 1 }, @ARGV;
