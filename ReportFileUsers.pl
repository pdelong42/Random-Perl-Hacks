#!/usr/bin/perl

use strict;
use warnings;

use English '-no_match_vars';
use Getopt::Long qw( :config no_ignore_case );

=pod

an example of wrapping this in a Bourne Shell function:

   function foo { sudo sh -c "rpm -qa $* && rpm -qla $* | ./ReportFileUsers.pl -s -p && yum update $*" ; }

Pass this the same args as you would to "sudo yum update ...".  Be
sure to include all dependencies explicitly, or you won't get a
complete picture.  To put it plainly, if yum tells you that it's
installing new packages for new dependencies, then go back and add
those to your command-line explicitly.

Incidentally, this does the "reverse lookup":

   function bar { sudo ./ReportFileUsers.pl -n -r $* | xargs rpm -qf | sort | uniq ; }

This will tell you which packages will affect this process if they are updated.

=cut

my $nullinput = 0;
my $pidprint = 0;
my $singlecol = 0;
my $reverse = 0;

my $ProcDir = "/proc/[0123456789]*";

my( @paths, %PIDsToPaths, %PathsToPIDs, %PIDsToNames, %NamesToPIDs );

GetOptions(
   "null"    => \$nullinput,
   "pid"     => \$pidprint,
   "single"  => \$singlecol,
   "reverse" => \$reverse,
) or die "getopts error";

@paths = readline STDIN
   unless $nullinput;

chomp @paths;

foreach my $filename ( glob "${ProcDir}/maps" ) {

   my $hand;

   unless( open $hand, $filename ) {
      warn "unable to open $filename - skipping\n";
      next;
   }

   my( $PID ) = $filename =~ m{ ^ /proc/(\d+)/maps $ }x;

   foreach( readline $hand ) {

      my( $address, $perms, $offset, $dev, $inode, @tmp ) = split;

      next unless @tmp;

      my $pathname = "@tmp";

      next unless( $nullinput or grep { $pathname eq $ARG } @paths );

      ++$PathsToPIDs{ $pathname }{ $PID };
      ++$PIDsToPaths{ $PID }{ $pathname };
   }
}

if( @ARGV ) {

   my %tmp;

   foreach my $PID ( @ARGV ) {
      ++$tmp{ $ARG } foreach keys %{ $PIDsToPaths{ $PID } };
   }

   foreach( sort keys %tmp ) {
      next if( $ARG eq '/dev/zero (deleted)' );
      next unless m/^\//;
      print "$ARG\n"
   }

   exit;
}

foreach my $filename ( glob "${ProcDir}/stat" ) {

   my( $hand, $name, $PID );

   unless( open $hand, $filename ) {
      warn "unable to open $filename - skipping\n";
      next;
   }

   foreach( readline $hand ) {

      next unless m/^\s*(\S+)\s+\(([^)]*)\)/;

      $PID  = $1;
      $name = $2;

      warn "PID sanity check failed\n"
         unless "/proc/${PID}/stat" eq $filename;
   }

   ++$PIDsToNames{ $PID }{ $name };
   ++$NamesToPIDs{ $name }{ $PID };
}

sub PrintJoinedHashes {

   my %finalhash;

   my( $hashref1, $hashref3 ) = @_;

   foreach my $column1 ( sort keys %$hashref1 ) {

      my $hashref2 = $hashref1->{ $column1 };

      foreach my $column2 ( sort keys %$hashref2 ) {

         my $hashref4 = $hashref3->{ $column2 };

         foreach my $column3 ( sort keys %$hashref4 ) {

            if( $pidprint ) {
               ++$finalhash{ "$column1 $column2 $column3" };
            } elsif( not $singlecol ) {
               ++$finalhash{ "$column1 $column3" };
            } else {
               ++$finalhash{ "$column1" };
            }
         }
      }
   }

   print "$finalhash{ $ARG }x $ARG\n"
      foreach sort keys %finalhash;
}

PrintJoinedHashes \%NamesToPIDs, \%PIDsToPaths;

printf "\n";

PrintJoinedHashes \%PathsToPIDs, \%PIDsToNames;
