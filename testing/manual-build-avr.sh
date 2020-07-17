#!/bin/bash

# Simple script for manual building of local gcc+avr-libc.

BB_ARCH=avr

REGRESSION_RECIPIENTS="dinuxbg@gmail.com"

# Do not send any email for this session
Mail()
{
  true
}

bb_daily_target_test()
{
  local PREV_BUILD_TAG=${1}
  local BUILD_TAG=${2}

  bb_clean

  local GCC_TOT=`cd gcc && git rev-parse HEAD`
  local BINUTILS_TOT=`cd binutils && git rev-parse HEAD`
  local AVRLIBC_TOT=`cd avrlibc && git rev-parse HEAD`
  local WINAVR_URL=`cd winavr && git rev-parse HEAD`

  echo "gcc ${GCC_TOT}" >> ${LOGDIR}/${BUILD_TAG}/versions.txt
  echo "binutils ${BINUTILS_TOT}" >> ${LOGDIR}/${BUILD_TAG}/versions.txt
  echo "avr-libc ${AVRLIBC_TOT}" >> ${LOGDIR}/${BUILD_TAG}/versions.txt
  echo "winavr ${WINAVR_URL}" >> ${LOGDIR}/${BUILD_TAG}/versions.txt

  # Build binutils
  bb_config binutils "--disable-gdb --target=avr"
  bb_make binutils "-j`nproc`"
  bb_make binutils "install"

  export PATH=${PREFIX}/bin:${PATH}

  bb_config gcc "--target=avr --enable-languages=c,c++ --disable-nls --disable-libssp --with-dwarf2"
  bb_make gcc "-j`nproc`"
  bb_make gcc "install"

  # Libc
  (cd ${WORKSPACE}/avrlibc && ./bootstrap) || error "failed to bootstrap avr-libc source"
  bb_config avrlibc '--host=avr'
  bb_make avrlibc "-j`nproc`"
  bb_make avrlibc "install"

  # avrtest
  bb_source_command winavr "make -C avrtest"

  # Get the simulator under PATH
  export PATH=${WORKSPACE}/winavr/avrtest:${PATH}

}


. `dirname ${0}`/buildbot-lib.sh

bb_init ${@}

bb_daily_build
