#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

# Simple script for manual building of gcc+newlib ToT.
#
# It is assumed that source directories are already setup, and
# desired HEADs are checked out.

BB_ARCH=pru

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

  bb_record_git_heads binutils gcc newlib

  # Build binutils
  bb_config binutils "--disable-gdb --target=pru"
  bb_make binutils "-j`nproc`"
  bb_make binutils "install"

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
  bb_config gcc "--target=pru --with-newlib --enable-languages=c,c++,rust --enable-checking=yes,rtl"
  bb_make gcc "-j`nproc`"
  bb_make gcc "install"

  # Make sure documentation is still in order
  bb_make gcc "pdf"

  # Save all the logs
  bb_gather_log_files ${BUILD_TAG}
}


. `dirname ${0}`/buildbot-lib.sh

bb_init_workspace ${@}
bb_init_builddir ${@}

bb_daily_build
