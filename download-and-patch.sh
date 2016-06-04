#!/bin/bash

# Sample script to download vanilla upstream projects
# and apply patches for the GCC PRU toolchain.

# On which upstream commits to apply patches. I frequently rebase so
# expect these to be somewhat random.
GCC_BASECOMMIT=3d3f5dc5ca848f5bf7eaf61b9254815791cfe6f0
BINUTILS_BASECOMMIT=de3da6457440a16311c7972e673a3c33e9621763
NEWLIB_BASECOMMIT=e6413b0a64cfb429d0e4e1034f84b2e4483c1013

# You can export your (local) repositories to speed up
# compilation.
test -z "$GCC_GIT" && GCC_GIT=https://github.com/mirrors/gcc
test -z "$BINUTILS_GIT" && BINUTILS_GIT=https://github.com/bminor/binutils-gdb
test -z "$NEWLIB_GIT" && NEWLIB_GIT=https://github.com/wallento/newlib-cygwin

# If you have already checked out GCC or binutils, then references
# could save you some bandwidth
#GCC_GIT_REFERENCE="--single-branch --reference=$HOME/projects/misc/gcc"
#BINUTILS_GIT_REFERENCE="--single-branch --reference=$HOME/projects/misc/binutils-gdb"
#NEWLIB_GIT_REFERENCE="--single-branch --reference=$HOME/projects/misc/newlib-cygwin"

MAINDIR=`pwd`
PATCHDIR=`pwd`/patches
SRC=`pwd`/src

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
  local REF="$4"
  wget $URL/archive/$COMMIT.tar.gz -O $SRC/"$PRJ"-"$COMMIT".tar.gz
  if [ $? -eq 0 ]; then
    cd $SRC
    tar -xvf "$PRJ"-"$COMMIT".tar.gz
    mv "$PRJ"-"$COMMIT" $PRJ
    cd $PRJ
    git init . && git add . && git commit -m "Import."
  else
    git clone --single-branch $URL $SRC/$PRJ $REF|| die Could not clone $URL
    cd $SRC/$PRJ
    git checkout -b tmp-pru $COMMIT || die Could not checkout $PRJ commit $COMMIT
  fi
  ls $PATCHDIR/$PRJ | sort | while read PATCH
  do
    git am -3 < $PATCHDIR/$PRJ/$PATCH || die "Could not apply patch $PATCH for $PRJ"
  done
  cd $MAINDIR
}

RETDIR=`pwd`

[ -d $SRC ] && die Incremental builds not supported. Cleanup and retry, e.g. 'git clean -fdx'
mkdir -p $SRC

# Checkout baseline and apply patches.
prepare_source binutils-gdb $BINUTILS_GIT $BINUTILS_BASECOMMIT "$BINUTILS_GIT_REFERENCE"
prepare_source gcc $GCC_GIT $GCC_BASECOMMIT "$GCC_GIT_REFERENCE"
prepare_source newlib-cygwin $NEWLIB_GIT $NEWLIB_BASECOMMIT "$NEWLIB_GIT_REFERENCE"

cd $RETDIR

echo Done.
