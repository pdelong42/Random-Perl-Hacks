#!/usr/bin/perl

use strict;
use warnings;

use English '-no_match_vars';
use Getopt::Long qw( :config no_ignore_case );

my( $hand, %tally );

my $kh_file = $ENV{ HOME } . '/.ssh/known_hosts';

my $kh_old = $kh_file . ".OLD";
my $kh_new = $kh_file . ".NEW";

GetOptions(
   'file=s' => \$kh_file,
   'old=s'  => \$kh_old,
   'new=s'  => \$kh_new,
) or die "getopt error\n";

open( $hand, $kh_file )
   or die "unable to read $kh_file\n";

foreach( readline $hand ) {
   my( $host, $cipher, $hash ) = split;
   push @{ $tally{ "$cipher $hash" } }, split( ',', $host );
}

foreach( keys %tally ) {
   my $tmp = join ',', sort @{ $tally{ $ARG } };
   $tally{ $ARG } = $tmp;
}

die "$kh_new exists - aborting\n"
   if -f $kh_new;

open( $hand, '>'. $kh_new )
   or die "unable to write $kh_new\n";

print $hand "$tally{ $ARG } $ARG\n"
   foreach sort { $tally{ $a } cmp $tally{ $b } } keys %tally;

die "$kh_old exists - aborting\n"
   if -f $kh_old;

rename $kh_file, $kh_old
   or die "unable to rename $kh_file to $kh_old - aborting\n";

die "$kh_file exists - aborting\n"
   if -f $kh_file;

rename $kh_new, $kh_file
   or die "unable to rename $kh_new to $kh_file - aborting\n";

=pod

ToDo:

 - sort IP addresses properly

 - add ability to merge multiple files into one

=cut
