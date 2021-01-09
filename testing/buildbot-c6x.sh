#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

# Simple script for automatic daily testing of gcc+newlib ToT.

BINUTILS_URL=git://sourceware.org/git/binutils-gdb.git
GCC_URL=https://github.com/mirrors/gcc
NEWLIB_URL=https://github.com/mirror/newlib-cygwin
BB_ARCH=c6x

REGRESSION_RECIPIENTS="dinuxbg@gmail.com"


bb_daily_target_test()
{
  local PREV_BUILD_TAG=${1}
  local BUILD_TAG=${2}

  bb_clean

  bb_update_source binutils ${BINUTILS_URL}
  bb_update_source gcc ${GCC_URL}
  bb_update_source newlib ${NEWLIB_URL}

  # Prepare tree for release, and write proper versioning info.
  pushd ${WORKSPACE}/gcc || error "failed to enter gcc"
  ./contrib/gcc_update origin master
  popd

  local GCC_TOT=`cd gcc && git rev-parse HEAD`
  local BINUTILS_TOT=`cd binutils && git rev-parse HEAD`
  local NEWLIB_TOT=`cd newlib && git rev-parse HEAD`

  echo "gcc ${GCC_TOT}" >> ${LOGDIR}/${BUILD_TAG}/versions.txt
  echo "binutils ${BINUTILS_TOT}" >> ${LOGDIR}/${BUILD_TAG}/versions.txt
  echo "newlib ${NEWLIB_TOT}" >> ${LOGDIR}/${BUILD_TAG}/versions.txt

  # Build binutils
  bb_config binutils "--disable-gdb --target=tic6x-none-elf"
  bb_make binutils "-j`nproc`"
  bb_make binutils "install"

  export PATH=${PREFIX}/bin:${PATH}

  # GCC pass 1: no libc yet
  bb_config gcc "--target=tic6x-none-elf --with-newlib --without-headers --enable-languages=c --enable-checking=yes,rtl"
  bb_make gcc "-j`nproc`"
  bb_make gcc "install"

  # Libc
  bb_config newlib "--target=tic6x-none-elf --enable-newlib-io-long-long --enable-newlib-io-long-double --enable-newlib-io-c99-formats"
  bb_make newlib "-j`nproc`"
  bb_make newlib "install"

  # GCC pass 2: full feature set
  bb_config gcc "--target=tic6x-none-elf --with-newlib --enable-languages=c,c++ --enable-checking=yes,rtl"
  bb_make gcc "-j`nproc`"
  bb_make gcc "install"

  # Make sure documentation is still in order
  bb_make gcc "pdf"

  # Save all the logs
  bb_gather_log_files ${BUILD_TAG}
}


. `dirname ${0}`/buildbot-lib.sh

bb_init ${@}

bb_daily_build
