#!/usr/bin/perl

=pod

The intent here is to get a monolithic dump of an Apache config file.  Feed it
the name of an Apache config file, and it will follow all the Include
directives, inserting their contents as it finds them, and removing all
standalone comments.  The idea is to keep from losing your mind following
includes, and save you the trouble of mentally filtering-out the comments that
nobody bothers deleting from the stock config file.

Don't go assuming that this strictly follows the same rules that Apache does
when it parses these files (assuming it even enforces a consistent grammar,
etc.).  This is meant strictly as a convenience (but I'm sure it will gather
more steam over time).

=cut

use strict;
use warnings;

use English '-no_match_vars';
use Getopt::Long qw( :config no_ignore_case );

our $depth = 0;

my $cont = '';
my $verbose = 1;
my $maxDepth = 3;

sub say { print "@_\n" }

sub myglob { split ' ', qx( echo @_ ) } # footnote 1 #

sub ProcessFile($);

sub ProcessFiles{ ProcessFile $ARG foreach @_ }

sub ProcessFile($) {

   my $fh;
   my $filename = shift;

   unless( open $fh, $filename ) {
      say "# unable to open $filename - skipping";
      return;
   }

   foreach( readline $fh ) {

      # strip blank lines and comments
      next if m{ ^ \s* (?: \# | $ ) }x;

      $ARG = "$cont$ARG";

      if( m{ \\ $ }x ) {
         chomp;
         s/\\$//;
         $cont = $ARG;
         next;
      }

      $cont = '';

      # condense non-leading space
      s/(?!^)\b[[:blank:]]+/ /g;

      # extract include filename
      unless( m{ ^ \s* Include \s+ ( \S+ ) }ix ) {
         # print and do next iteration if not include
         print;
         next;
      }

      # process the include file
      my $include = $1;

      local $depth;

      if( ++$depth > $maxDepth ) {
         say "# cannot include $include; nesting level exceeded - skipping";
         print;
         next;
      }

      say "# entering $include" if $verbose;
      ProcessFiles myglob $include;
      say "# exiting  $include" if $verbose;
   }
}

GetOptions(
   'verbose' => \$verbose,
   'depth=i' => \$maxDepth,
) or die "getopt error";

ProcessFiles @ARGV;

=pod

Footnote 1:

This bad hack exists because the built-in glob() (as well as File::Glob) has a
bug in it, in which it does not recognize an inverted character class (it
instead treats the leading carat as a literal character like any other).

ToDo:

 - [DONE] compress whitespace - replace multiple consecutive spaces/tabs with a
single space; this might not be desirable, if it destroys indentation;
{preserves indentation}

 - reformat indentation for consistency;

 - [DONE] join continued lines (lines that are broken-up by backslash-escaped
newlines); {the solution is not elegant}

 - remove non-standalone comments (comments that are not the only thing on
their line); the trick here is to not blow away parts valid config directives
which use the hash-mark for other purposes besides comments

 - it might not be a bad idea to look at the code Apache uses to parse its own
config files;

=cut
