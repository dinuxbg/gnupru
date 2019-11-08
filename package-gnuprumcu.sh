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

rm -fr packaging/gnuprumcu
cp -Rfp $SRC/gnuprumcu packaging/gnuprumcu || die "Could not copy gnuprumcu sources"

# TODO: sign the package
cd packaging/gnuprumcu || die "failed to cd"
dpkg-buildpackage -us -uc 2>&1 | tee dpkg-buildpackage.log || die Failed to build debian package.

cd $RETDIR

echo Done.
