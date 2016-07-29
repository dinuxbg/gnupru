#!/bin/bash

# Sample script to produce Debian package for gcc+newlib

MAINDIR=`pwd`
SRC=`pwd`/src

die()
{
  echo ERROR: $@
  exit 1
}


RETDIR=`pwd`

[ -d $SRC ] || die $SRC does not exist. Please run ./download-and-patch.sh

VERSION=`head -1 packaging/gcc-pru/debian/changelog | grep -o '(.\+)'| sed -e 's/(\|)//g' | cut -f1 -d-`
cp -Rfp $SRC/gcc/ packaging/gcc-pru/gcc-pru_$VERSION/ || die Could not copy gcc sources
cp -Rfp $SRC/newlib-cygwin/newlib/ packaging/gcc-pru/gcc-pru_$VERSION/ || die Could not copy newlib sources
cp -Rfp $SRC/newlib-cygwin/libgloss/ packaging/gcc-pru/gcc-pru_$VERSION/ || die Could not copy newlib sources
cd packaging/gcc-pru || die
rm -fr gcc-pru*/.git
tar cjf gcc-pru_$VERSION.orig.tar.bz2 gcc-pru_$VERSION/ || die Could not create gcc source archive
rm -fr gcc-pru_$VERSION

# TODO: sign the package
dpkg-buildpackage -us -uc 2>&1 | tee dpkg-buildpackage.log || die Failed to build debian package.

cd $RETDIR

echo Done.
