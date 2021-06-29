#!/usr/bin/perl

use strict;
use warnings;

use English qw( -no_match_vars );

local $OUTPUT_RECORD_SEPARATOR = $INPUT_RECORD_SEPARATOR;
local $INPUT_RECORD_SEPARATOR;

my %tally;

++$tally{ $ARG } foreach readline( STDIN ) =~ m{ .*? (?:href|src) = " ( [^"]* ) }xmsgc;

print foreach sort keys %tally;
