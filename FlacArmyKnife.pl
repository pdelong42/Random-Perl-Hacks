#!/usr/bin/perl

use strict;
use warnings;
use File::Find;
use File::Path;
use Getopt::Long qw( :config no_ignore_case );

my( $help, $manual, $overwrite, $test, $unflac, $verbose, @paths, %changes );

my $source = "";
my $target = "";
my $flac = "/usr/bin/flac";
my $metaflac = "/usr/bin/metaflac";
my $suffix = "ogg";

my $decoder = <<'EOF'; # footnote 2 #
/usr/bin/flac \
--totally-silent \
--decode \
--stdout \
--decode-through-errors \
EOF

my $encoder = <<'EOF'; # footnote 2 #
/usr/bin/oggenc \
--quiet \
--title '%s' \
--album '%s' \
--tracknum '%s' \
--artist '%s' \
--genre '%s' \
--date '%s' \
--bitrate=128 \
--min-bitrate=96 \
--max-bitrate=225 \
- \
EOF

my %Separator = ( # footnote 1 #

   GENRE => ' | ',
   ARTIST => ' | ',
   ALBUM => ' | ',
   TRACKNUMBER => ' - ',
   TITLE => "\n"
);

sub mysort { sort @_ }

sub PostProcessExit {

   my $name = shift();
   if( $? < 0 ) {
      die "${name} failed to execute: $!";
   } elsif( $? & 127 ) {
      die sprintf( "${name} died with signal %d, %s coredump", ($? & 127), ( ($? & 128) ? 'with' : 'without' ) );
   }
   $? >> 8;
}

sub metaflac {

   my @stdout = qx($metaflac @_ 2>&1);
   my $exit = PostProcessExit 'metaflac';
   warn "metaflac exited with value ${exit} with args [@_]" unless( $exit == 0 );
   return @stdout;
}

sub testflac {

   my $filename = ${ shift() };
   qx($flac --test --totally-silent '$filename' 2>&1);
   my $exit = PostProcessExit 'testflac';
   die "flac exited with value ${exit}" if( $exit < 0 or $exit > 1 );
   print "file [${filename}] failed integrity test - skipping\n" if $exit == 1;
   return $exit;
}

sub unflac {

   my $input = ${ shift() };
   my %notes = %{ shift() };

   $input =~ m(^${source}/(.*)\.flac$);

   my $output = "${target}/${1}.${suffix}";

   if( not $overwrite and -f $output ) {
      print "not overwriting file: ${output}\n";
      return;
   }

   my @dirs = ( $output =~ m(^(.*)/[^/]+) );

   eval { mkpath \@dirs };

   if( $@ ) {
      print "skipping ${input} - couldn't create @{dirs}: $@";
      return;
   }

   my @args;

   foreach my $key ( qw( TITLE ALBUM TRACKNUMBER ARTIST GENRE DATE ) ) { # footnote 1 #

      my $note = $notes{ $key };
      next unless $note;
      $note =~ s(')('"'"')g; # ugly hack #
      push @args, $note;
   }

   unless( scalar( @args ) == 6 ) { # footnote 5 #
      print "not enough comments - skipping ${input}\n";
      return;
   }

   my $encoderx = sprintf $encoder, @args;

   $input =~ s(')('"'"')g; # ugly hack #
   $output =~ s(')('"'"')g; # ugly hack #

   qx($decoder '${input}' | $encoderx > '${output}');

   my $exit = PostProcessExit 'unflac'; # footnote 4 #

   die "flac exited with value ${exit}" if( $exit < 0 or $exit > 1 );

   print "file [${input}] couldn't be decoded - skipping\n" if $exit == 1;
}

sub FlacArmyKnife {

   return unless -f;
   return unless m(\.flac$);

   my $original = $_;
   s(')('"'"')g; # ugly hack #
   my $filename = $_;

   return if( $test and &testflac( \$filename ) );

   my %comments;
   foreach( metaflac "--block-number=2 --list '${filename}'" ) {
      next unless m(^\s+comment\[\d+\]:\s+([^=]+)=(.*)$);
      $comments{ $1 } = $2;
   }

   my $args = "";

   foreach my $key ( qw( TITLE ALBUM TRACKNUMBER ARTIST GENRE DATE ) ) { # footnote 1 #

      unless( $comments{ $key } or $changes{ $key } ) {
         print qq(file [${original}] has no comment ``${key}''\n);
      }
      next unless $changes{ $key };
      $comments{ $key } = $changes{ $key };
      my $comment = $comments{ $key };
      $comment =~ s(')('"'"')g; # ugly hack #
      $args .= " --remove-tag ${key} --set-tag ${key}='${comment}'";
   }

   metaflac "${args} '${filename}'" if $args;

   unflac( \$original, \%comments ) if $unflac;

   return unless $verbose;

   foreach my $key ( qw( GENRE ARTIST ALBUM TRACKNUMBER TITLE ) ) { # footnote 1 #
      my $comment = $comments{ $key } ? $comments{ $key } : "?";
      printf( $comment . $Separator{ $key } );
   }
}

my %Options = (

   "change=s"   => \%changes,
   "decoder=s"  => \$decoder,
   "encoder=s"  => \$encoder,
   "flac=s"     => \$flac,
   "help"       => \$help,
   "manual"     => \$manual,
   "Metaflac=s" => \$metaflac,
   "overwrite"  => \$overwrite,
   "path=s"     => \@paths,
   "source=s"   => \$source,
   "Suffix=s"   => \$suffix,
   "target=s"   => \$target,
   "Test"       => \$test,
   "unflac"     => \$unflac,
   "verbose"    => \$verbose,
);

my %FindOpts = (

   "wanted"     => \&FlacArmyKnife,
   "preprocess" => \&mysort,
   "no_chdir"   => 1,
);

&GetOptions( %Options ) or die "getopts failed";

@paths = ( @paths, @ARGV );
@paths = $ENV{ PWD } unless @paths;

find \%FindOpts, @paths;

=pod

=head1 NAME

FlacArmyKnife - perform a variety of batch operations on FLAC files

=head1 SYNOPSIS

=over 8

FlacArmyKnife [options] [paths]

=back

=head1 OPTIONS AND ARGUMENTS

=item B<sample> (required/optional)

Sample.  (rinse, lather, repeat...)

=head1 EXAMPLES

=item FlacArmyKnife ...

Sample.  (rinse, lather, repeat...)

=head1 DESCRIPTION

Fill in later.

=head1 BUGS (FEATURES?)

If you don't specify any options on the command-line, the script will happily
find any flac files in the hierarchy rooted at the current directory.  It just
won't do anything useful with them once it finds them.  Depending on how many
flac files it finds, this can result in a long time sitting there watching it
(and wondering what it's doing) until the script finishes and exits.
[perhaps fix this by printing help]

Config file support is non-existent, and the command-line options are
overloaded as a result.  If you want to achieve the effect of a configuration
file, you'll need to write a wrapper script.  There are many good ways to do
this:

   [fill me in later]

My calling conventions are inconsistent.

Relative paths cannot be used with decoding/encoding without using the --source
or --target options.

Regarding the "ugly hacks" comments in the code, I'm convinced there's a better
and more elegant way of solving that problem.  I'll just be farked if I can
think of it right now.  My intuition wants to say it's something resembling the
way null-terminators can be used in something like "find ... -print0 | xargs -0
...", to get around the classic Unix difficulty of filenames with spaces.  But
this is Perl, not shell.

=head1 HISTORY

I wrote this because I wanted to rip my entire CD collection, but I couldn't
decide whether to encode in MP3 or OGG, or what encoding options to use in
either case.  But I know myself, and I know that it would never get done if I
made it contingent on the conclusions I reached from my researches into this
dilemma.  So I decided to go ahead and start ripping to FLAC, deferring my
dilemma and buying myself time to research, but also making headway on the
*physical* component of the project.

Indeed, it is rather handy to have your whole collection in a lossless format
like FLAC anyway.  The reason being is that if I do change my mind later, and
if in a fit of perfectionist control-freakish anal-retentiveness I decide I
want to re-encode all my music using different sampling rates, quality
settings, shaping, encoder, container, or whatever, then I can do so without
risking wear-and-tear on my CD collection, and without the monotonous task of
sitting there swapping disks and making sure all the CDDB info is right.
(Gosh, that sentence was long.)  It's also handy if you're a curmudgeon (like
me) who prefers to use OGG, but also wants to share your music with someone.
You can make a batch conversion from the "original" FLAC to a more mainstream
format like MP3 (as most hardware players don't support OGG).

Of course, this is all assuming you have ample disk to store all those FLAC
files, which is hardly an issue these days, disk being as cheap as it is.  It
was also quite convenient that I had recently reformatted a pair of 80 GB disks
for UDF.

There are also other anciliary benefits provided by this script, such as: the
ability to re-write the same comment in many FLAC files at once, which is handy
for correcting comments that have the same mistake for every song of an album
(and would be a pain using "metaflac" on its own); the ability to display the
comments from a subset of your FLAC files in a listing that's readable (to me,
anyhow); the ability to test the integrity of many FLAC files in one go.  The
funny thing is, I wrote those features first, as part of a utility script,
fully intending on writing the FLAC-to-OGG or FLAC-to-MP3 converter as a
separate program entirely.  But I realized I would be duplicating (and
maintaining) a bunch of duplicated code if I didn't condense all of the above
into one script.  What a funny backwards world we live in.

Incidentally, the script assumes that the FLAC files were generated by Grip,
using the following config file options:

   GRIP 2
   exe /usr/bin/flac
   cmdline -V --best -T TITLE="%*n" -T ALBUM="%y - %*d" -T TRACKNUMBER=%t -T ARTIST="%*a" -T GENRE="%G" -T DATE=%y -o %*m %*w
   extension flac

I briefly considered making the name of the program the fusion of two other
names - "flac" and "acid" - and hence calling it "flaccid".  But then good
sense prevailed.  Supposing, by some freak chance, it became popular - I didn't
want to become known as the guy behind "flaccid".  Try mentioning *that* in a
job interview.  Hah.

Anyway, I'm sure you're sick of hearing me talk by now (or rather, you've
stopped reading).  So go forth and enjoy.

=head1 FOOTNOTES

=head2 Footnote 1:

Consider making these refer to a single user-configurable list, or at-least
three separate user-configurable ones.

=head2 Footnote 2:

Yeah, I know it's ugly.  But not as ugly as stuffing it all on one line.  Feel
free to use the config file to replace it with whatever you like.

=head2 Footnote 3:

(empty)

=head2 Footnote 4:

The previous line doesn't sit well with me, because there are two commands
being executed, and I can't test the exit values for both.  In fact, I don't
know which command the Perl-provided exit value actually belongs to.  This may
compel me to split this into two command invocations, passing a temp file
between them, instead of using a pipe.

=head2 Footnote 5:

It might be a good idea to make a provision for ignoring this, and just padding
empty comments with the empty string.

=head1 TODO

write docs on config file "support" (started, ongoing);

write Pod manual page (started, ongoing);

incorporate Pod2Usage;

document later:

[specify the oggenc and lame sample command-lines]

[give sample config files for both MacOS+Fink and Fedora Core 4] "because those
are the platforms I have at my fingertips" [also simplify the ogg example and
default - use quality setting instead of bitrate]

It's dangerous to use --source by itself, without also using --target...

=cut
