#!/bin/bash

# Simple script for automatic daily testing of binutils ToT.

# All directories must be relative to the workspace!
BINUTILS_SRC=binutils-gdb
BINUTILS_BUILD=binutils-gdb-build
BINUTILS_URL=git://sourceware.org/git/binutils-gdb.git
PREFIX=opt
LOGDIR=logs

die()
{
  echo "ERROR: $@"
  exit 1
}

[ $# == 1 ] || die "usage: $0 <WORKSPACE>"

WORKSPACE=`realpath "$1"`
[ -d "$WORKSPACE" ] || die "$WORKSPACE is not a directory"


cd $WORKSPACE
mkdir -p $WORKSPACE/$PREFIX
mkdir -p $WORKSPACE/$LOGDIR

[ -d "$BINUTILS_SRC" ] || git clone $BINUTILS_URL $BINUTILS_SRC || die "initial $BINUTILS_URL clone failed"

(cd $BINUTILS_SRC && git remote prune origin) || die "failed to prune remote"
(cd $BINUTILS_SRC && git fetch origin && git checkout origin/master) || die "failed to sync $BINUTILS_URL"

BINUTILS_TOT=`cd $BINUTILS_SRC && git rev-parse HEAD`

build_test_binutils()
{
  local CONFIG_PARAMS=$@

  cd $WORKSPACE || die "cannot cd to $WORKSPACE"

  # TODO - this is controversial!
  rm -fr $WORKSPACE/$PREFIX

  rm -fr $BINUTILS_BUILD
  mkdir -p $BINUTILS_BUILD
  cd $BINUTILS_BUILD

  $WORKSPACE/$BINUTILS_SRC/configure --prefix=$WORKSPACE/$PREFIX $CONFIG_PARAMS || die "Could not configure Binutils"
  make -j4 || die "Failed to build Binutils"
  make pdf || die "Failed to build Binutils documentation"
  make install || die "Failed to install Binutils"
  make check RUNTESTFLAGS=--target_board=pru-sim || "Binutils test failed"

  cd $WORKSPACE
}

build_test_binutils_logged()
{
  local STSTR
  local CONFIG_ID=$1
  shift
  local CONFIG_PARAMS=$@

  (build_test_binutils $CONFIG_PARAMS) 2>&1 | tee $WORKSPACE/build.log
  local ST=$?

  if [ $ST = 0 ]; then STSTR=PASS; else STSTR=FAIL; fi

  local TARNAME=$WORKSPACE/$LOGDIR/binutils-`date +%Y%m%d%H%M`-$BINUTILS_TOT-$CONFIG_ID-$STSTR.tar
  tar caf $TARNAME \
     $WORKSPACE/build.log \
     $WORKSPACE/$BINUTILS_BUILD/binutils/binutils.{log,sum} \
     $WORKSPACE/$BINUTILS_BUILD/gas/testsuite/gas.{log,sum} \
     $WORKSPACE/$BINUTILS_BUILD/ld/ld.{log,sum}

     # $WORKSPACE/$BINUTILS_BUILD/sim/testsuite/sim.{log,sum}
  bzip2 -9 $TARNAME
  rm -f $WORKSPACE/build.log
}

build_test_binutils_logged pru "--disable-gdb --disable-sim --target=pru"
build_test_binutils_logged pru_target_all "--disable-gdb --disable-sim --target=pru --enable-targets=all"
