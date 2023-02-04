#!/bin/bash

# Sample script to download vanilla upstream projects.

# Official packages to download.

# TODO - wait for GCC 13 release!  
#GCC_URL=http://ftpmirror.gnu.org/gcc/gcc-13.0/gcc-13.0.tar.xz
GCC_URL=https://gcc.gnu.org/pub/gcc/snapshots/13-20230129/gcc-13-20230129.tar.xz

# TODO - wait for 2.41 release!
#BINUTILS_URL=http://ftpmirror.gnu.org/binutils/binutils-2.41.tar.bz2
BINUTILS_URL=https://github.com/bminor/binutils-gdb/archive/ba268471bf9a2b76efc0d7a9c05291f7e8cd4424.tar.gz

NEWLIB_URL=ftp://sourceware.org/pub/newlib/newlib-4.2.0.20211231.tar.gz
GNUPRUMCU_URL=https://github.com/dinuxbg/gnuprumcu/releases/download/v0.9.1/gnuprumcu-0.9.1.tar.gz

MAINDIR=`pwd`
SRC=`pwd`/src

die()
{
  echo ERROR: $@
  exit 1
}

prepare_source_tarball()
{
  local PRJ=$1
  local URL=$2

  # Do not download if already available.
  gzip --test $SRC/"$PRJ".tar.gz && return 0

  wget $URL -O $SRC/"$PRJ".tar.gz || die "failed to download $URL"
  mkdir -p "${SRC}/${PRJ}"
  pushd "${SRC}/${PRJ}"
  tar --strip-components=1 -xaf "${SRC}/${PRJ}.tar.gz" || die "failed to extract ${PRJ}.tar.gz"
  popd
}

RETDIR=`pwd`

[ -d $SRC ] && die Incremental builds not supported. Cleanup and retry, e.g. 'git clean -fdx'
mkdir -p $SRC

# Checkout baseline.
prepare_source_tarball binutils-gdb $BINUTILS_URL
prepare_source_tarball gcc $GCC_URL
prepare_source_tarball newlib-cygwin $NEWLIB_URL
prepare_source_tarball gnuprumcu $GNUPRUMCU_URL

cd $RETDIR

echo Done.
