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

CROSS_TARGET=aarch64-unknown-linux-gnu
#CROSS_TARGET=armv8l-unknown-linux-gnueabihf

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

  [[ `cat /proc/sys/fs/binfmt_misc/status` = enabled ]] || error "binfmt not enabled for userspace QEMU emulation"

  # Build binutils
  bb_config binutils "--with-sysroot=${PREFIX}/sysroot --disable-gdb --disable-sim --target=${CROSS_TARGET}"
  bb_make binutils "-j`nproc`"
  bb_make binutils "install"

  export PATH=${PREFIX}/bin:${PATH}

  # GCC pass 1: no libc yet
  bb_config gcc "--target=${CROSS_TARGET} --with-sysroot=${PREFIX}/sysroot --with-newlib --without-headers --disable-shared --disable-threads --enable-languages=c --disable-libatomic --disable-libmudflap --disable-libssp --disable-libquadmath --disable-libgomp --disable-nls --disable-bootstrap"
  bb_make gcc "-j`nproc`" inhibit-libc=true all-gcc
  bb_make gcc "-j`nproc`" inhibit-libc=true install-gcc
  bb_make gcc "-j`nproc`" inhibit-libc=true all-target-libgcc
  bb_make gcc "-j`nproc`" inhibit-libc=true install-target-libgcc

  # Prepare Linux headers
  # TODO - do not build in the source directory.
  bb_source_command linux make ARCH=arm64 CROSS_COMPILE=${CROSS_TARGET}- headers_install
  mkdir -p ${PREFIX}/sysroot
  cp -Rfp ${WORKSPACE}/linux/usr/include ${PREFIX}/sysroot/

  # Linux headers
  bb_config glibc "--host=${CROSS_TARGET} BUILD_CC=gcc CC=${CROSS_TARGET}-gcc --enable-shared --with-headers=${WORKSPACE}/linux/usr/include/ --disable-multilib --enable-kernel=5.0.0 --prefix=${PREFIX}/sysroot"
  bb_make glibc "-j`nproc`" "install-headers install_root=${PREFIX}/sysroot"

  # Libc
  bb_project_clean glibc
  bb_config glibc "--host=${CROSS_TARGET} BUILD_CC=gcc CC=${CROSS_TARGET}-gcc --disable-werror --enable-shared --enable-obsolete-rpc --with-headers=${WORKSPACE}/linux/usr/include/ --enable-kernel=5.0.0 --prefix=/"
  bb_make glibc "-j`nproc`"
  bb_make glibc "install install_root=${PREFIX}/sysroot"

  # GCC pass 2: full feature set
  bb_project_clean gcc
  bb_config gcc "--target=${CROSS_TARGET} --with-sysroot=${PREFIX}/sysroot --with-native-system-header-dir=/include --enable-shared --enable-tls --enable-languages=c,c++,fortran --disable-nls --disable-bootstrap"
  bb_make gcc "-j`nproc`"
  bb_make gcc "install"

  # Required for userspace QEMU to work
  export QEMU_LD_PREFIX=${PREFIX}/sysroot

  # Test glibc
  bb_make --ignore-errors glibc "-j`nproc` check"

  # Test GCC
  bb_make gcc "-j`nproc` check-gcc-c"
  bb_make gcc "-j`nproc` check-gcc-c++"

  # Save all the logs
  bb_gather_log_files ${BUILD_TAG}
}


. `dirname ${0}`/buildbot-lib.sh

bb_init_workspace ${@}
bb_init_builddir ${@}

bb_daily_build
