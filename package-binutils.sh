#!/bin/bash

# Sample script to produce Debian package for binutils-pru

MAINDIR=`pwd`
SRC=`pwd`/src

die()
{
  echo ERROR: $@
  exit 1
}


RETDIR=`pwd`

[ -d $SRC ] || die $SRC does not exist. Please run ./download-and-patch.sh

VERSION=`head -1 packaging/binutils-pru/debian/changelog | grep -o '(.\+)'| sed -e 's/(\|)//g' | cut -f1 -d-`
# TODO - remove the last -1 from the version
cp -Rfp $SRC/binutils-gdb/ packaging/binutils-pru/binutils-pru_$VERSION/ || die Could not copy binutils sources
cd packaging/binutils-pru || die
rm -fr binutils-pru*/.git
tar cjf binutils-pru_$VERSION.tar.bz2 binutils-pru_$VERSION/ || die Could not create binutils source archive
rm -fr binutils-pru_$VERSION

# TODO: sign the package
dpkg-buildpackage -us -uc 2>&1 | tee dpkg-buildpackage.log || die Failed to build debian package.

cd $RETDIR

echo Done.
