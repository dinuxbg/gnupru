#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

# Simple script for automatic daily testing of gcc+avrlibc ToT.

BINUTILS_URL=https://github.com/bminor/binutils-gdb
GCC_URL=https://github.com/mirrors/gcc
AVRLIBC_URL=https://github.com/avrdudes/avr-libc
WINAVR_URL=https://gitlab.com/dinuxbg/winavr-code
BB_ARCH=avr

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
  bb_update_source avrlibc ${AVRLIBC_URL} main
  bb_update_source winavr ${WINAVR_URL}

  # Write conforming versioning info.
  bb_gcc_touch_source_tree ${GCC_BRANCH}

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

  # Send to real mailing list,
  pushd ${WORKSPACE}/avr-gcc-build || error "failed to enter avr-gcc-build"

  # Don't spam GCC testresults mailing list for what is probably a local setup issue.
  [ `grep '^FAIL:' gcc/testsuite/gcc/gcc.sum | wc -l` -gt 1000 ] && error "too many C failures"
  [ `grep '^FAIL:' gcc/testsuite/g++/g++.sum | wc -l` -gt 12000 ] && error "too many C++ failures"

  # Without libstdc++, we end up with thousands of spurious FAILS.
  # Enabling libstdc++ is non-trivial for AVR, so to spare GCC mailing
  # servers from megabytes of spurious failures, simply remove them.
  #
  # We simply track regressions for C++.
  local AVR_KNOWN_FAILURES=${LOGDIR}/avr-known-failures
  [ -f $AVR_KNOWN_FAILURES ] || grep '^\(UNSUPPORTED\|FAIL\):' ${LOGDIR}/${BUILD_TAG}/g++.sum | awk '{print $2}' > ${AVR_KNOWN_FAILURES}
  # Filter out g++.sum
  cp gcc/testsuite/g++/g++.sum buildbot-sum-tmp
  cat buildbot-sum-tmp | grep -f ${AVR_KNOWN_FAILURES} -v  > gcc/testsuite/g++/g++.sum

  echo -e "WARNING: Many C++ failures have been omitted due to lack of libstdc++ on AVR!\nOnly G++ regressions are reported below.\n\n" > avr-warning.txt
  ../gcc/contrib/test_summary -p avr-warning.txt -m ${SUMMARY_RECIPIENTS} | sh
  popd

  bb_check_for_regressions ${PREV_BUILD_TAG} ${BUILD_TAG}
}


. `dirname ${0}`/buildbot-lib.sh

bb_init ${@}

bb_daily_build
