#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

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

  bb_record_git_heads binutils gcc avrlibc atest

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
}


. `dirname ${0}`/buildbot-lib.sh

bb_init_workspace ${@}
bb_init_builddir ${@}

bb_daily_build
