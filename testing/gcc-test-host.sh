#!/bin/bash

# Simple script for automatic testing host for GCC regressions.

die()
{
  echo "ERROR: $@"
  exit 1
}

[ $# != 2 ] && die "Usage: $0 <vanilla-commit> <patched-commit>"

COMMITID_VANILLA=${1}
COMMITID_PATCHED=${2}

BUILD_VANILLA=`pwd`/tmp/host-build-vanilla
BUILD_PATCHED=`pwd`/tmp/host-build-patched
SRC=`pwd`/gcc
LOGDIR=`pwd`/logs

rm -fr ${BUILD_VANILLA} ${BUILD_PATCHED}
mkdir -p ${BUILD_VANILLA} ${BUILD_PATCHED} $LOGDIR

build_test_gcc()
{
  local BUILDDIR=${1}
  shift
  local TAG=${1}

  cd ${BUILDDIR} || die
  ${SRC}/configure --disable-multilib --enable-languages=c,c++ || die
  make -j5 || die
  make check-gcc-c check-gcc-c++  || die
  local FILES="gcc/testsuite/gcc/gcc.log gcc/testsuite/gcc/gcc.sum gcc/testsuite/g++/g++.log gcc/testsuite/g++/g++.sum"
  for i in ${FILES}
  do
    cp "${i}" "${LOGDIR}/`basename ${i}`-${TAG}"
  done
}


DATETAG=`date +%Y%m%d%H%M`
cd ${SRC} && git reset --hard ${COMMITID_VANILLA}
build_test_gcc ${BUILD_VANILLA} ${DATETAG}-host-vanilla
cd ${SRC} && git reset --hard ${COMMITID_PATCHED}
build_test_gcc ${BUILD_PATCHED} ${DATETAG}-host-patched

# TODO - re-enable
#rm -fr ${BUILD_VANILLA} ${BUILD_PATCHED}
