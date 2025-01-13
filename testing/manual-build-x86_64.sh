#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

# Simple script for manual building of gcc+glibc ToT.
#
# It is assumed that source directories are already setup, and
# desired HEADs are checked out.

BB_ARCH=x86_64

BTARGET=x86_64-pc-linux-gnu

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

  bb_record_git_heads binutils gcc glibc

  # Build binutils
  bb_config binutils "--disable-gdb --target=${BTARGET}"
  bb_make binutils "-j`nproc`"
  bb_make binutils "install"

  export PATH=${PREFIX}/bin:${PATH}

  # GCC pass 1: no libc yet
  bb_config gcc "--target=${BTARGET} --disable-multilib --without-headers --enable-languages=c --enable-checking=yes,rtl --disable-libssp --disable-gcov --with-sysroot=/"
  bb_make gcc "-j`nproc`"
  bb_make gcc "install"

  # Libc
  bb_config glibc "--target=${BTARGET} --disable-multilib"
  bb_make glibc "-j`nproc`"
  bb_make glibc "install"

  # libiberty complains about changed LDFLAGS.
  bb_make gcc "distclean"

  # GCC pass 2: full feature set
  bb_config gcc "--target=${BTARGET} --disable-multilib --enable-languages=c,c++ --enable-checking=yes,rtl --disable-libssp --disable-gcov"
  bb_make gcc "-j`nproc`"
  bb_make gcc "install"

  # Make sure documentation is still in order
  # bb_make gcc "pdf"

  # Save all the logs
  bb_gather_log_files ${BUILD_TAG}
}


. `dirname ${0}`/buildbot-lib.sh

bb_init_workspace ${@}
bb_init_builddir ${@}

bb_daily_build
