#!/bin/bash

# Sample script to download vanilla upstream projects
# and apply patches for the GCC PRU toolchain.

# On which upstream commits to apply patches. I frequently rebase so
# expect these to be somewhat random.
GCC_URL=http://ftpmirror.gnu.org/gcc/gcc-10.1.0/gcc-10.1.0.tar.xz
BINUTILS_URL=http://ftpmirror.gnu.org/binutils/binutils-2.34.tar.bz2
NEWLIB_URL=ftp://sourceware.org/pub/newlib/newlib-3.3.0.tar.gz
GNUPRUMCU_URL=https://github.com/dinuxbg/gnuprumcu/releases/download/v0.2.0/gnuprumcu-0.2.0.tar.gz

MAINDIR=`pwd`
PATCHDIR=`pwd`/patches
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

# Checkout baseline and apply patches.
prepare_source_tarball binutils-gdb $BINUTILS_URL
prepare_source_tarball gcc $GCC_URL
prepare_source_tarball newlib-cygwin $NEWLIB_URL
prepare_source_tarball gnuprumcu $GNUPRUMCU_URL

cd $RETDIR

echo Done.
