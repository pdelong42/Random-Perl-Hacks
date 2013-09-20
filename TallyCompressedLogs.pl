#!/usr/bin/perl

=pod

I don't foresee much use for this script outside the one occasion I wrote it
for.  But who knows, it could come in handy later, so I'm filing it away here.

What is does is to total up the size of all files with the same name across
different zipfile archives.  In this instance, it was nine servers with
compressed log files from previous days in the month.

=cut

use strict;
use warnings;

use English;
use File::Find;
use Data::Dumper;
use Archive::Zip;

my( @zipfiles, %archives, %groups, %totals );

my $wanted = sub {

   return unless -f;
   return unless m/\.zip$/i;

   push @zipfiles, $File::Find::name;
};

$Data::Dumper::Indent = 1;

push( @ARGV, '.' ) unless @ARGV;

find $wanted, @ARGV;

foreach my $zipfile ( @zipfiles ) {

   my $zipper = new Archive::Zip $zipfile;

   unless( $zipper ) {
      print "ERROR: could not open $zipfile - skipping\n";
      next;
   }

   my @members = members $zipper;

   foreach( @members ) {

      my $filename = fileName         $ARG;
      my $archive  = externalFileName $ARG;
      my $size     = uncompressedSize $ARG;
      #                                ...I'm Popeye the Sailor Man...

      unless( defined $filename and defined $archive and defined $size ) {
         print "WARNING: unable to access all elements of the following member - skipping\n";
         print Dumper $ARG;
         next;
      }

      if( exists $totals{ $filename } ) {
         $totals{ $filename } += $size;
      } else {
         $totals{ $filename } = 0;
      }

      push @{ $archives{ $filename } }, $archive;
   }
}

foreach( keys %archives ) {

   my $tmp = join "\n", sort @{ $archives{ $ARG } };
   my $tot = $totals{ $ARG };

   push @{ $groups{ $tmp } }, "$ARG ${tot}";
}

my @stanzas;

foreach( sort keys %groups ) {

   my $stanza = '';

   $stanza .= "$ARG\n";
   $stanza .= "$ARG\n" foreach sort @{ $groups{ $ARG } };

   push @stanzas, $stanza;
}

print join( "\n", @stanzas );
