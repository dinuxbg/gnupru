#!/bin/bash

# On which upstream commits to apply patches. I frequently rebase so
# expect these to be somewhat random.
GCC_BASECOMMIT=f32182a91aaa044679c880db019914123ba0bbd0
BINUTILS_BASECOMMIT=5c1a8bf5167c14550a3699243283a010a0651123

GCC_GIT=https://github.com/mirrors/gcc.git
BINUTILS_GIT=https://github.com/bminor/binutils-gdb.git

# If you have already checked out GCC or binutils, then references
# could save you some bandwidth
#GCC_GIT_REFERENCE="--reference=$HOME/projects/misc/gcc"
#BINUTILS_GIT_REFERENCE="--reference=$HOME/projects/misc/binutils-gdb"

MAINDIR=`pwd`
PATCHDIR=`pwd`/patches
SRC=`pwd`/src
BUILD=`pwd`/build
PREFIX=$HOME/bin/pru-gcc

die()
{
  echo ERROR: $@
  exit 1
}

prepare_source()
{
  local PRJ=$1
  local URL=$2
  local COMMIT=$3
  local REF=$4
  git clone $URL $SRC/$PRJ $REF|| die Could not clone $URL
  cd $SRC/$PRJ
  git checkout -b tmp-pru $COMMIT || die Could not checkout $PRJ commit $COMMIT
  ls $PATCHDIR/$PRJ | sort | while read PATCH
  do
    git am -3 < $PATCHDIR/$PRJ/$PATCH || die "Could not apply patch $PATCH for $PRJ"
  done
  cd $MAINDIR
}

build_binutils()
{
  cd $BUILD/binutils-gdb
  $SRC/binutils-gdb/configure --target=pru --prefix=$PREFIX --disable-nls --disable-gdb || die Could not configure Binutils
  make -j4 || die Could not build Binutils
  make install || die Could not install Binutils
}


build_gcc()
{
  cd $BUILD/gcc
  $SRC/gcc/configure --target=pru --prefix=$PREFIX --disable-nls --without-headers --enable-languages=c || die Could not configure GCC
  make -j4 || die Could not build GCC
  make install || die Could not install GCC
}

RETDIR=`pwd`
mkdir -p $SRC
mkdir -p $BUILD/gcc
mkdir -p $BUILD/binutils-gdb

prepare_source binutils-gdb $BINUTILS_GIT $BINUTILS_BASECOMMIT $BINUTILS_GIT_REFERENCE
prepare_source gcc $GCC_GIT $GCC_BASECOMMIT $GCC_GIT_REFERENCE

build_binutils
build_gcc

cd $RETDIR

echo Done.
