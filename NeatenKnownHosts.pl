#!/usr/bin/perl

use strict;
use warnings;

use English '-no_match_vars';
use Getopt::Long qw( :config no_ignore_case );

my( $hand, %tally );

my $known_hosts = $ENV{ HOME } . '/.ssh/known_hosts';

GetOptions(
   'hosts=s' => \$known_hosts,
) or die "getopt error\n";

open( $hand, $known_hosts )
   or die "unable to read $known_hosts";

foreach( readline $hand ) {
   my( $host, $cipher, $hash ) = split;

   my @addresses = split ',', $host;
   push @{ $tally{ $hash } }, join( ',', sort( @addresses ) );
}

foreach( keys %tally ) {
   my $tmp = '';
   $tmp .= sprintf( "$ARG\n" ) foreach sort @{ $tally{ $ARG } };
   $tally{ $ARG } = $tmp;
}

print "$tally{ $_ }\n"
   foreach sort { $tally{ $a } cmp $tally{ $b } } keys %tally;
