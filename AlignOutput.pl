#!/usr/bin/perl

=pod

This is meant to be a generic pretty-printer for tabular terminal output.  Lots
of existing commands don't automatically align their output, making for
difficult reading.  This short script  attempts to address that.

Examples:

   AlignOutput.pl < /etc/fstab
   mount | AlignOutput.pl

=cut

use strict;
use warnings;
use English '-no_match_vars';
use Getopt::Long qw( :config no_ignore_case );

my $leftflush;
my $separators = '[\t\s]+';

GetOptions(
   'leftflush'    => \$leftflush,
   'separators=s' => \$separators,
) or die "getopt error\n";

my( @lines, @widest );

foreach( readline STDIN ) {

   my $i = -1;
   my @fields = split qr{$separators};

   push @lines, \@fields;

   foreach( @fields ) {

      ++$i;

      my $widest;
      my $length = length;

      $widest[ $i ] = 0 unless defined $widest[ $i ];
      $widest[ $i ] = $length if( $length > $widest[ $i ] );
   }
}

my $format = '';

$format .= sprintf( "%%%s%ss", $leftflush ? '-' : '', 1 + $ARG )
   foreach @widest;

$format .= "\n";

my $widest = scalar @widest;

#print "DEBUG: widest = $widest; format = $format\n";

foreach( @lines ) {

   my @line = @$ARG;
   my $width = scalar @line;
   my $diff = $widest - $width;

   #printf "DEBUG: width = $width; diff = $diff\n";

   push( @line, '' ) while( $diff-- > 0 );

   printf $format, @line;
}
