#!/bin/bash

# Sample script to produce Debian package for gnuprumcu

MAINDIR=`pwd`
SRC=`pwd`/src

die()
{
  echo ERROR: $@
  exit 1
}


RETDIR=`pwd`

[ -d $SRC ] || die $SRC does not exist. Please run ./download-and-patch.sh

cd $SRC/gnuprumcu || die
debuild -i -us -uc -b || die "failed to build debian package"

cd $RETDIR

echo Done.
