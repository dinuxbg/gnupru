#!/bin/bash

# Simple script for automatic daily testing of gcc+newlib ToT.

BINUTILS_URL=git://sourceware.org/git/binutils-gdb.git
GCC_URL=https://github.com/mirrors/gcc
NEWLIB_URL=https://github.com/mirror/newlib-cygwin

REGRESSION_RECIPIENTS="dinuxbg@gmail.com"


bb_daily_target_test()
{
  local PREV_BUILD_TAG=${1}
  local BUILD_TAG=${2}

  bb_clean

  bb_update_source binutils ${BINUTILS_URL}
  bb_update_source gcc ${GCC_URL}
  bb_update_source newlib ${NEWLIB_URL}

  local GCC_TOT=`cd gcc && git rev-parse HEAD`
  local BINUTILS_TOT=`cd binutils && git rev-parse HEAD`
  local NEWLIB_TOT=`cd newlib && git rev-parse HEAD`

  echo "gcc ${GCC_TOT}" >> ${LOGDIR}/${BUILD_TAG}/versions.txt
  echo "binutils ${BINUTILS_TOT}" >> ${LOGDIR}/${BUILD_TAG}/versions.txt
  echo "newlib ${NEWLIB_TOT}" >> ${LOGDIR}/${BUILD_TAG}/versions.txt

  # Build binutils
  bb_config binutils "--disable-gdb --target=pru"
  bb_make binutils "-j`nproc`"
  bb_make binutils "install"
  bb_make binutils "check RUNTESTFLAGS=--target_board=pru-sim"

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
  # Note: Disable hosted libstdc++ features due to commit:
  #   a64e72607dcb77cf7e923100cc6c71651e2da433
  #   PR libstdc++/86846 Alternative to pointer-width atomics
  bb_config gcc "--target=pru --with-newlib --enable-languages=c,c++ --disable-hosted-libstdcxx --enable-checking=yes,rtl"
  bb_make gcc "-j`nproc`"
  bb_make gcc "install"

  # Make sure documentation is still in order
  bb_make gcc "pdf"

  # Test GCC
  bb_make gcc "check-gcc-c RUNTESTFLAGS=--target_board=pru-sim"
  bb_make gcc "check-gcc-c++ RUNTESTFLAGS=--target_board=pru-sim"

  # Save all the logs
  bb_gather_log_files ${BUILD_TAG}

  # Send to real mailing list,
  pushd ${WORKSPACE}/gcc-build || error "failed to enter gcc-build"
  # TODO - switch to mail list when stability is reached!
  ../gcc/contrib/test_summary -m dinuxbg@gmail.com | sh
  popd

  bb_check_for_regressions ${PREV_BUILD_TAG} ${BUILD_TAG}
}


. `dirname ${0}`/buildbot-lib.sh

bb_init ${@}

# Workaround debian's inability to set heirloom as default
mkdir -p ${WORKSPACE}/tools/bin
ln -s `which s-nail` ${WORKSPACE}/tools/bin/Mail 1>/dev/null 2>&1
export PATH=${WORKSPACE}/tools/bin:${PATH}

bb_daily_build
