#!/usr/bin/perl

# Note that the log format assumed here is very custom.
# It's adapted to other formats easily enough, but please be aware that
# modifications must be made for it to work elsewhere.

use strict;
use warnings;
use Time::Local;
use English '-no_match_vars';
use Getopt::Long qw( :config no_ignore_case );

my( @fields, @times, $invert, %match, $count, $reverse );

my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my %monidx = map { $months[ $ARG ] => $ARG } 0..$#months;

my $logline = qr{

   ^

   # host IP
   ( .+? )
   (?<!,)

   \s+

   ( \S+ )

   \s+

   # remote username
   ( \S+ )

   \s+

   # time/date
   \[
   ( [^\]]+ )
   \]

   \s+

   # request
   \"
   ( .*? )
   (?<!\\) \"

   \s+

   # status code
   ( \S+ )

   \s+

   # size
   ( \S+ )

   \s+

   # referer
   \"
   ( .*? )
   (?<!\\) \"

   \s+

   # user-agent
   \"
   ( .*? )
   (?<!\\) \"

#   \s+

#   # virtual host
#   \"
#   ( .+? )
#   (?<!\\) \"

}x;

sub OutsideTimeRanges {

   return $invert unless @times;

   my( $day, $mon, $year, $hour, $min, $sec, $tz ) = split '[/:\s]', shift;

   my $num = $monidx{ $mon };
   $mon = $num;

   $tz =~ m/(\D?)(\d\d)(\d\d)/;
   my $offset = 60 * ( $2 + 60 * $3 );
   $offset *= -1 if( $1 ne '-' );

   my $logtime = $offset + timelocal $sec, $min, $hour, $day, $mon, $year;
   my $tmp = scalar grep { $ARG < $logtime } @times;

   return( $tmp % 2 == 0 xor $invert ); # footnote 3 #
}

=pod

# It's a lot simpler if you don't care what timezone the log file / httpd
# process thinks it's in.

sub OutsideTimeRanges {

   return $invert unless @times;

   my( $day, $mon, $year, $hour, $min, $sec ) = split '[/:\s]', shift;

   my $num = $monidx{ $mon };
   $mon = $num;

   my $logtime = timelocal $sec, $min, $hour, $day, $mon, $year;
   my $tmp = scalar grep { $ARG < $logtime } @times;

   return( $tmp % 2 == 0 xor $invert ); # footnote 3 #
}

=cut

GetOptions(

   'Files=s'  => \@ARGV,
   'fields=s' => \@fields, # footnote 5 #
   'match=s'  => \%match,
   'times=s'  => \@times,  # footnote 4 #
   'invert'   => \$invert,
   'count'    => \$count,
   'reverse'  => \$reverse,

) or die "getopts error";

my %stats;

foreach( @ARGV ) {

   my $fh;
   my $mode = '<';

#   if( m/\.gz$/ ) {
#      use PerlIO::gzip;
#      $mode .= ':gzip';
#   }

   unless( open( $fh, $mode, $ARG ) ) {
      warn "unable to open $ARG for reading\n";
      next;
   }

   LOGLINE: foreach( readline $fh ) {

      chomp;

      unless( m/$logline/ ) {
         warn "error parsing log entry $ARG\n";
         next;
      }

      #printf STDERR $ARG;

      next if OutsideTimeRanges $4;

      my %tmp;

      $tmp{ host    } = $1;
      $tmp{ ruser   } = $2;
      $tmp{ user    } = $3;
      $tmp{ request } = $5;
      $tmp{ status  } = $6;
      $tmp{ size    } = $7;
      $tmp{ referer } = $8;
      $tmp{ agent   } = $9;
      $tmp{ vhost   } = $10;

      #@{ $tmp{ hosts } } = split '[,\s]+', $tmp{ host }; # footnote 6 #

      ( $tmp{ method }, $tmp{ uri }, $tmp{ version } )
         = split '\s+', $tmp{ request };

      foreach( keys %match ) { # footnote 1 #
         next unless exists $tmp{ $ARG };
         next LOGLINE unless( $tmp{ $ARG } =~ m/^$match{ $ARG }$/ );
      }

      my @keys;

      foreach( @fields ) {
         push( @keys, $tmp{ $ARG } ) if defined $tmp{ $ARG };
      }

      ++$stats{ "@keys" };
   }
}

if( $count ) {

   my $sorter = $reverse
      ? sub { $stats{ $b } <=> $stats{ $a } }
      : sub { $stats{ $a } <=> $stats{ $b } };

   print "$stats{ $ARG }x $ARG\n" foreach sort $sorter keys %stats;

} else {

   my $sorter = $reverse
      ? sub { $b cmp $a }
      : sub { $a cmp $b };

   print "$ARG x$stats{ $ARG }\n" foreach sort $sorter keys %stats;

}

my $total = 0;

$total += $ARG foreach values %stats;

print "total: $total\n";

=pod

Footnote 1:

There is an implied "and" here, since we abort the outer loop if *any* match
fails.

Footnote 2:

It's assumed that if the user specifies a non-existent field, they still want
to see output based on other fields.

Footnote 3:

This works by simply counting interval boundaries.  A log entry is considered
outside of any time range if there is an even number of interval bounds less
than its timestamp value, and it is considered inside of a time range if there
is an odd number of interval bounds less than its timestamp value.  This
situation is reversed if the "invert" option is specified.

Footnote 4:

Order doesn't matter here, because these interval bounds eventually get
(effectively) sorted anyway.

Footnote 5:

Order matters here, because they are used in the order they are found.

Footnote 6:

Figure-out a way to make this selectable as a field and to incorporate it into
the match logic.

=cut
