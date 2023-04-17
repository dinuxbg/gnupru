#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

# Put it in an empty directory and invoke it from crontab. Example:
#  0 8 * * * /home/user/testbot-workspace/crontest.sh



cd `dirname ${0}`

# For testing
export SUMMARY_RECIPIENTS=dinuxbg@gmail.com

# For real.
# export SUMMARY_RECIPIENTS=gcc-testresults@gcc.gnu.org


# On every second Sunday...
if [ x`date +%u` = x7 -a x$((`date +%U` % 2)) = x0 ]
then
  # Test AVR and PRU on all active branches.
  LOGDIR=`pwd`/avr-gcc-10-logs GCC_BRANCH=releases/gcc-10 ./gnupru/testing/buildbot-avr.sh .
  LOGDIR=`pwd`/avr-gcc-11-logs GCC_BRANCH=releases/gcc-11 ./gnupru/testing/buildbot-avr.sh .
  LOGDIR=`pwd`/avr-gcc-12-logs GCC_BRANCH=releases/gcc-12 ./gnupru/testing/buildbot-avr.sh .
  LOGDIR=`pwd`/avr-gcc-13-logs GCC_BRANCH=releases/gcc-13 ./gnupru/testing/buildbot-avr.sh .
  GCC_BRANCH=master ./gnupru/testing/buildbot-avr.sh .

  LOGDIR=`pwd`/pru-gcc-10-logs GCC_BRANCH=releases/gcc-10 ./gnupru/testing/buildbot-pru.sh .
  LOGDIR=`pwd`/pru-gcc-11-logs GCC_BRANCH=releases/gcc-11 ./gnupru/testing/buildbot-pru.sh .
  LOGDIR=`pwd`/pru-gcc-12-logs GCC_BRANCH=releases/gcc-12 ./gnupru/testing/buildbot-pru.sh .
  LOGDIR=`pwd`/pru-gcc-13-logs GCC_BRANCH=releases/gcc-13 ./gnupru/testing/buildbot-pru.sh .
fi

# Test PRU everyday.
GCC_BRANCH=master ./gnupru/testing/buildbot-pru.sh .
