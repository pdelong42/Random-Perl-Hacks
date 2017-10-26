#!/bin/sh

set -euo pipefail

if test "$UID" -ne "0" ; then
   echo ERROR: you are not root - please re-run this with sufficient privileges
   exit 1
fi

if test -z "$*" ; then
   echo "Running this with no args will match all packages.  Are you sure you want to do this?"
   echo -n "<enter> to continue, <ctrl>-c to abort: "
   read
fi

BASE=$(dirname $(realpath $0))

rpm -qa $*
rpm -qal $* | ${BASE}/ReportFileUsers.pl -s -p
yum update $*
