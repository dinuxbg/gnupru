#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

# Simple script for automatic update of the source trees.

BINUTILS_URL=https://github.com/bminor/binutils-gdb
GCC_URL=https://github.com/mirrors/gcc
NEWLIB_URL=https://github.com/bminor/newlib
AVRLIBC_URL=https://github.com/avrdudes/avr-libc
ATEST_URL=https://github.com/sprintersb/atest
EMBENCH_IOT_URL=https://github.com/embench/embench-iot

true ${GCC_BRANCH:=master}

# Who to send a short regression report to
REGRESSION_RECIPIENTS="dinuxbg@gmail.com"

# Default full report recipient. Caller can set this
# environment variable to override the default.
true ${SUMMARY_RECIPIENTS:=dinuxbg@gmail.com}


bb_daily_update_sources()
{
  bb_update_source binutils ${BINUTILS_URL}
  bb_update_source gcc ${GCC_URL} ${GCC_BRANCH}
  bb_update_source newlib ${NEWLIB_URL}
  bb_update_source avrlibc ${AVRLIBC_URL} main
  bb_update_source atest ${ATEST_URL}
  bb_update_source embench ${EMBENCH_IOT_URL} embench-2.0-branch

  # Write conforming versioning info.
  bb_gcc_touch_source_tree ${GCC_BRANCH}
}


. `dirname ${0}`/buildbot-lib.sh

bb_init_workspace ${@}

bb_daily_update_sources
