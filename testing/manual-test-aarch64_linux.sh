#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

# Simple script for manual building and testing of gcc+glibc ToT.
#
# It is assumed that source directories are already setup, and
# desired HEADs are checked out.
#
# The steps to build a cross linux toolchain were obtained from
# https://github.com/riscv-collab/riscv-gnu-toolchain

BB_ARCH=aarch64_linux

#CROSS_TARGET=aarch64-unknown-linux-gnu
CROSS_TARGET=armv8l-unknown-linux-gnueabihf

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
  bb_config binutils "--disable-gdb --disable-sim --target=${CROSS_TARGET}"
  bb_make binutils "-j`nproc`"
  bb_make binutils "install"

  export PATH=${PREFIX}/bin:${PATH}

  # GCC pass 1: no libc yet
  bb_config gcc "--target=${CROSS_TARGET} --with-newlib --without-headers --disable-shared --disable-threads --enable-languages=c --disable-libatomic --disable-libmudflap --disable-libssp --disable-libquadmath --disable-libgomp --disable-nls --disable-bootstrap"
  bb_make gcc "-j`nproc`" inhibit-libc=true all-gcc
  bb_make gcc "-j`nproc`" inhibit-libc=true install-gcc
  bb_make gcc "-j`nproc`" inhibit-libc=true all-target-libgcc
  bb_make gcc "-j`nproc`" inhibit-libc=true install-target-libgcc

  # Linux headers
  # TODO - how to obtain them "officially"?
  bb_config glibc "--target=${CROSS_TARGET} --enable-shared --with-headers=${WORKSPACE}/linux-headers --disable-multilib --enable-kernel=5.0.0"
  bb_make glibc "-j`nproc`"
  bb_make glibc "install-headers"

  # Libc
  bb_config glibc "--target=${CROSS_TARGET} CC=${CROSS_TARGET}-gcc --disable-werror --enable-shared --enable-obsolete-rpc --with-headers=${WORKSPACE}/linux-headers --enable-kernel=5.0.0"
  bb_make glibc "-j`nproc`"
  bb_make glibc "install"

  # GCC pass 2: full feature set
  bb_config gcc "--target=${CROSS_TARGET} --enable-shared --enable-tls --enable-languages=c,c++,fortran --disable-nls --disable-bootstrap"
  bb_make gcc "-j`nproc`"
  bb_make gcc "install"

  # Test glibc
  bb_make glibc "-j`nproc` check RUNTESTFLAGS=--target_board=qemu"

  # Test GCC
  bb_make gcc "-j`nproc` check-gcc-c RUNTESTFLAGS=--target_board=qemu"
  bb_make gcc "-j`nproc` check-gcc-c++ RUNTESTFLAGS=--target_board=qemu"

  # Save all the logs
  bb_gather_log_files ${BUILD_TAG}
}


. `dirname ${0}`/buildbot-lib.sh

bb_init_workspace ${@}
bb_init_builddir ${@}

bb_daily_build
