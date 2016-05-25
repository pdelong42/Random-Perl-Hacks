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
   or die "unable to read $kh_file";

foreach( readline $hand ) {
   my( $host, $cipher, $hash ) = split;

   my @addresses = split ',', $host;
   push @{ $tally{ "$cipher $hash" } }, join( ',', sort( @addresses ) );
}

foreach( keys %tally ) {
   my $tmp = '';
   $tmp .= sprintf( "$ARG\n" ) foreach sort @{ $tally{ $ARG } };
   $tally{ $ARG } = $tmp;
}

open( $hand, '>'. $kh_new )
   or die "unable to write $kh_new";

print $hand "$tally{ $_ }\n"
   foreach sort { $tally{ $a } cmp $tally{ $b } } keys %tally;
