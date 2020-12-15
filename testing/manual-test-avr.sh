#!/bin/bash

# Simple script for manual building and testing of local gcc+avr-libc.

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

  # Setup avrtest, per:
  #    https://sourceforge.net/p/winavr/code/HEAD/tree/trunk/avrtest/
  #    https://lists.gnu.org/archive/html/avr-gcc-list/2009-09/msg00016.html
  export DEJAGNU=${PREFIX}/dejagnurc
  mkdir -p `dirname ${DEJAGNU}`
  echo "# WARNING - automatically generated!" > ${DEJAGNU}
  echo "set avrtest_dir \"${WORKSPACE}/winavr/avrtest\"" >> ${DEJAGNU}
  echo "set avrlibc_include_dir \"${PREFIX}/avr/include\"" >> ${DEJAGNU}
  echo 'set boards_dir {}' >> ${DEJAGNU}
  echo 'lappend boards_dir "${avrtest_dir}/dejagnuboards"' >> ${DEJAGNU}

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

  # Get the simulator under PATH. Needed for gcc test suite.
  export PATH=${WORKSPACE}/winavr/avrtest:${PATH}

  # Test binutils. Do not let random test case failures to mark
  # the entire build as bad.
  bb_config binutils "--disable-gdb --target=avr"
  bb_make binutils "-j`nproc`"
  bb_make binutils "install"
  bb_make --ignore-errors binutils "-k check RUNTESTFLAGS=--target_board=atmega128-sim"

  # Test GCC
  bb_make gcc "-j`nproc` check-gcc-c RUNTESTFLAGS=--target_board=atmega128-sim"
  bb_make gcc "-j`nproc` check-gcc-c++ RUNTESTFLAGS=--target_board=atmega128-sim"

  # Save all the logs
  bb_gather_log_files ${BUILD_TAG}

}


. `dirname ${0}`/buildbot-lib.sh

bb_init ${@}

bb_daily_build
