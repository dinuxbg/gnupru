#!/bin/bash

# Put it in an empty directory and invoke it from crontab. Example:
#  0 8 * * * /home/user/testbot-workspace/crontest.sh



cd `dirname ${0}`

# For testing
export SUMMARY_RECIPIENTS=dinuxbg@gmail.com

# For real.
# export SUMMARY_RECIPIENTS=gcc-testresults@gcc.gnu.org



if [ x`date +%u` = x7 ]
then
  # Once a week, test AVR and PRU on all active branches.
  LOGDIR=`pwd`/avr-gcc-8-logs GCC_BRANCH=releases/gcc-8 ./gnupru/testing/buildbot-avr.sh .
  LOGDIR=`pwd`/avr-gcc-9-logs GCC_BRANCH=releases/gcc-9 ./gnupru/testing/buildbot-avr.sh .
  LOGDIR=`pwd`/avr-gcc-10-logs GCC_BRANCH=releases/gcc-10 ./gnupru/testing/buildbot-avr.sh .
  GCC_BRANCH=master ./gnupru/testing/buildbot-avr.sh .

  LOGDIR=`pwd`/pru-gcc-10-logs GCC_BRANCH=releases/gcc-10 ./gnupru/testing/buildbot-pru.sh .
fi

# Test PRU everyday.
GCC_BRANCH=master ./gnupru/testing/buildbot-pru.sh .
