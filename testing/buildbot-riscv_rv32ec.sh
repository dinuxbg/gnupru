#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

# Simple script for automatic daily testing of gcc+newlib ToT.

BB_ARCH=riscv_rv32ec

BB_GCC_TARGET_OPTIONS="--target=riscv32-none-elf --with-multilib-generator=rv32ec-ilp32e-- --with-abi=ilp32e --with-arch=rv32ec"

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

  bb_record_git_heads binutils gcc newlib

  # Setup testing for RV32EC
  export DEJAGNU=${PREFIX}/dejagnurc
  mkdir -p `dirname ${DEJAGNU}`
  echo "# WARNING - automatically generated!" > ${DEJAGNU}
  echo "lappend boards_dir \"${PREFIX}\"" >> ${DEJAGNU}
  echo "set_board_info sim,options \"--model RV32EC\"" > ${PREFIX}/riscv-rv32ec-sim.exp
  echo "set_board_info cflags   \" --specs=sim.specs [libgloss_include_flags] [newlib_include_flags]\"" >> ${PREFIX}/riscv-rv32ec-sim.exp
  echo "load_base_board_description \"riscv-sim\"" >> ${PREFIX}/riscv-rv32ec-sim.exp

  echo "gcc ${GCC_TOT}" >> ${LOGDIR}/${BUILD_TAG}/versions.txt
  echo "binutils ${BINUTILS_TOT}" >> ${LOGDIR}/${BUILD_TAG}/versions.txt
  echo "newlib ${NEWLIB_TOT}" >> ${LOGDIR}/${BUILD_TAG}/versions.txt

  # Build binutils
  # TODO - re-enable sim building
  bb_config binutils "--disable-gdb --disable-sim --target=riscv32-none-elf"
  bb_make binutils "-j`nproc`"
  bb_make binutils "install"
  # Check binutils without a target C compiler. All tests must pass.
  # TODO
  # bb_make binutils "-j`nproc` check RUNTESTFLAGS=--target_board=riscv-rv32ec-sim"

  export PATH=${PREFIX}/bin:${PATH}

  # GCC pass 1: no libc yet
  bb_config gcc "${BB_GCC_TARGET_OPTIONS} --with-newlib --without-headers --enable-languages=c --disable-libssp --enable-checking=yes,rtl"
  bb_make gcc "-j`nproc`"
  bb_make gcc "install"

  # Libc
  bb_config newlib "${BB_GCC_TARGET_OPTIONS} --enable-newlib-io-long-long --enable-newlib-io-long-double --enable-newlib-io-c99-formats"
  bb_make newlib "-j`nproc`"
  bb_make newlib "install"

  # GCC pass 2: full feature set
  bb_config gcc "${BB_GCC_TARGET_OPTIONS} --with-newlib --enable-languages=c,c++ --disable-libssp --enable-checking=yes,rtl"
  bb_make gcc "-j`nproc`"
  bb_make gcc "install"

  # Make sure documentation is still in order
  bb_make gcc "pdf"

  # Test newlib
  bb_make newlib "-j`nproc` check RUNTESTFLAGS=--target_board=riscv-rv32ec-sim"

  # Test GCC
  bb_make gcc "-j`nproc` check-gcc-c RUNTESTFLAGS=--target_board=riscv-rv32ec-sim"
  bb_make gcc "-j`nproc` check-gcc-c++ RUNTESTFLAGS=--target_board=riscv-rv32ec-sim"

  # Build binutils again - this time with a C compiler present.
  bb_make binutils "distclean"
  # TODO - re-enable sim building
  bb_config binutils "--disable-gdb --disable-sim --target=riscv32-none-elf"
  bb_make binutils "-j`nproc`"
  bb_make binutils "install"
  # Check binutils with a target C compiler.  Some tests may fail.
  bb_make --ignore-errors binutils "-j`nproc` check RUNTESTFLAGS=--target_board=riscv-rv32ec-sim"

  # Save all the logs
  bb_gather_log_files ${BUILD_TAG}

  # Don't spam GCC testresults mailing list for what is probably a local setup issue.
  [ `grep '^FAIL:' ${WORKSPACE}/riscv_rv32ec-gcc-build/gcc/testsuite/gcc/gcc.sum | wc -l` -gt 1000 ] && error "too many C failures"
  [ `grep '^FAIL:' ${WORKSPACE}/riscv_rv32ec-gcc-build/gcc/testsuite/g++/g++.sum | wc -l` -gt 2000 ] && error "too many C++ failures"

  # Send to real mailing list,
  pushd ${WORKSPACE}/riscv_rv32ec-gcc-build || error "failed to enter riscv_rv32ec-gcc-build"
  ../gcc/contrib/test_summary -m ${SUMMARY_RECIPIENTS} | sh
  popd

  bb_check_for_regressions ${PREV_BUILD_TAG} ${BUILD_TAG}
}


. `dirname ${0}`/buildbot-lib.sh

bb_init_workspace ${@}
bb_init_builddir ${@}

bb_daily_build
