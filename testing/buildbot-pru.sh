#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

# Simple script for automatic daily testing of gcc+newlib ToT.

BINUTILS_URL=https://github.com/bminor/binutils-gdb
GCC_URL=https://github.com/mirrors/gcc
NEWLIB_URL=https://github.com/bminor/newlib
BB_ARCH=pru

true ${GCC_BRANCH:=master}

# Who to send a short regression report to
REGRESSION_RECIPIENTS="dinuxbg@gmail.com"

# Default full report recipient. Caller can set this
# environment variable to override the default.
true ${SUMMARY_RECIPIENTS:=dinuxbg@gmail.com}


bb_daily_target_test()
{
  local PREV_BUILD_TAG=${1}
  local BUILD_TAG=${2}

  bb_clean

  bb_update_source binutils ${BINUTILS_URL}
  bb_update_source gcc ${GCC_URL} ${GCC_BRANCH}
  bb_update_source newlib ${NEWLIB_URL}

  # Write conforming versioning info.
  bb_gcc_touch_source_tree ${GCC_BRANCH}

  # Build binutils
  bb_config binutils "--disable-gdb --target=pru"
  bb_make binutils "-j`nproc`"
  bb_make binutils "install"
  # Check binutils without a target C compiler. All tests must pass.
  bb_make binutils "-j`nproc` check RUNTESTFLAGS=--target_board=pru-sim"

  export PATH=${PREFIX}/bin:${PATH}

  # GCC pass 1: no libc yet
  bb_config gcc "--target=pru --with-newlib --without-headers --enable-languages=c --enable-checking=yes,rtl"
  bb_make gcc "-j`nproc`"
  bb_make gcc "install"

  # Libc
  bb_config newlib "--target=pru --enable-newlib-io-long-long --enable-newlib-io-long-double --enable-newlib-io-c99-formats"
  bb_make newlib "-j`nproc`"
  bb_make newlib "install"

  # GCC pass 2: full feature set
  bb_config gcc "--target=pru --with-newlib --enable-languages=c,c++ --enable-checking=yes,rtl"
  bb_make gcc "-j`nproc`"
  bb_make gcc "install"

  # Make sure documentation is still in order
  bb_make gcc "pdf"

  # Test newlib
  bb_make newlib "-j`nproc` check RUNTESTFLAGS=--target_board=pru-sim"

  # Test GCC
  bb_make gcc "-j`nproc` check-gcc-c RUNTESTFLAGS=--target_board=pru-sim"
  bb_make gcc "-j`nproc` check-gcc-c++ RUNTESTFLAGS=--target_board=pru-sim"

  # Build binutils again - this time with a C compiler present.
  bb_make binutils "distclean"
  bb_config binutils "--disable-gdb --target=pru"
  bb_make binutils "-j`nproc`"
  bb_make binutils "install"
  # Check binutils with a target C compiler.  Some tests may fail.
  bb_make --ignore-errors binutils "-j`nproc` check RUNTESTFLAGS=--target_board=pru-sim"

  # Save all the logs
  bb_gather_log_files ${BUILD_TAG}

  # Don't spam GCC testresults mailing list for what is probably a local setup issue.
  [ `grep '^FAIL:' ${WORKSPACE}/pru-gcc-build/gcc/testsuite/gcc/gcc.sum | wc -l` -gt 1000 ] && error "too many C failures"
  [ `grep '^FAIL:' ${WORKSPACE}/pru-gcc-build/gcc/testsuite/g++/g++.sum | wc -l` -gt 3000 ] && error "too many C++ failures"

  # Send to real mailing list,
  pushd ${WORKSPACE}/pru-gcc-build || error "failed to enter pru-gcc-build"
  ../gcc/contrib/test_summary -m ${SUMMARY_RECIPIENTS} | sh
  popd

  bb_check_for_regressions ${PREV_BUILD_TAG} ${BUILD_TAG}
}


. `dirname ${0}`/buildbot-lib.sh

bb_init ${@}

bb_daily_build
