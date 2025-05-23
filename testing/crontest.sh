#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

# Put it in an empty directory and invoke it from crontab. Example:
#  0 8 * * * /home/user/testbot-workspace/crontest.sh


renice +10 $$ 2>/dev/null 1>/dev/null

cd `dirname ${0}`

# For testing
export SUMMARY_RECIPIENTS=dinuxbg@gmail.com

# For real.
# export SUMMARY_RECIPIENTS=gcc-testresults@gcc.gnu.org


# On every second Sunday...
if [ x`date +%u` = x7 -a x$((`date +%U` % 2)) = x0 ]
then
  # Test AVR and PRU on all active branches.
  GCC_BRANCH=releases/gcc-12 ./gnupru/testing/buildbot-sync.sh .
  LOGDIR=`pwd`/avr-gcc-12-logs ./gnupru/testing/buildbot-avr.sh .
  LOGDIR=`pwd`/pru-gcc-12-logs ./gnupru/testing/buildbot-pru.sh .

  GCC_BRANCH=releases/gcc-13 ./gnupru/testing/buildbot-sync.sh .
  LOGDIR=`pwd`/avr-gcc-13-logs ./gnupru/testing/buildbot-avr.sh .
  LOGDIR=`pwd`/pru-gcc-13-logs ./gnupru/testing/buildbot-pru.sh .

  GCC_BRANCH=releases/gcc-14 ./gnupru/testing/buildbot-sync.sh .
  LOGDIR=`pwd`/avr-gcc-14-logs ./gnupru/testing/buildbot-avr.sh .
  LOGDIR=`pwd`/pru-gcc-14-logs ./gnupru/testing/buildbot-pru.sh .

  GCC_BRANCH=releases/gcc-15 ./gnupru/testing/buildbot-sync.sh .
  LOGDIR=`pwd`/avr-gcc-15-logs ./gnupru/testing/buildbot-avr.sh .
  LOGDIR=`pwd`/pru-gcc-15-logs ./gnupru/testing/buildbot-pru.sh .
  LOGDIR=`pwd`/riscv_rv32ec-gcc-15-logs ./gnupru/testing/buildbot-riscv_rv32ec.sh .

  ./gnupru/testing/buildbot-sync.sh .
  ./gnupru/testing/buildbot-avr.sh .
  ./gnupru/testing/buildbot-riscv_rv32ec.sh .

  rm -fr avr-*-build riscv32-*-build arm-*-build riscv_rv32ec-*-build
fi

# Test PRU everyday.
./gnupru/testing/buildbot-sync.sh .
./gnupru/testing/buildbot-pru.sh .
