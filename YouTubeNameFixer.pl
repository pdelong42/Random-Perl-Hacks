#!/usr/bin/perl

use strict;
use warnings;

use File::Find;
use English qw( -no_match_vars );

my $wanted = sub {
   return unless m{ ( .* ) \- ( .{11} ) \. ( webm | mp4 | flv ) }x;
   print "$2 $3 $1\n";
};

push @ARGV, '.'
   unless @ARGV;

find $wanted, @ARGV;
