#!/bin/sh

# I found myself doing this so often, that I got sick of it and wrote this
# script.

if test -z $1 ; then
   echo please provide a hostname arg - aborting
   exit 1
fi

HOST=$1
DIR=Stuff/repos/github.com/pdelong42

ssh $HOST 'mkdir -p ~/'$DIR

SOURCE=~/${DIR}/Random-Perl-Hacks
DEST=${HOST}:${DIR}

echo copying $SOURCE to $DEST
scp -qr $SOURCE $DEST
