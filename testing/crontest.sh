#!/bin/bash

# Put it in an empty directory and invoke it from crontab. Example:
#  11 8 * * 7 /home/user/testbot-workspace/crontest-weekly.sh



cd `dirname ${0}`
export SUMMARY_RECIPIENTS=dinuxbg@gmail.com

LOGDIR=`pwd`/avr-gcc-8-logs GCC_BRANCH=releases/gcc-8 ./gnupru/testing/buildbot-avr.sh .
LOGDIR=`pwd`/avr-gcc-8-logs GCC_BRANCH=releases/gcc-8 ./gnupru/testing/buildbot-avr.sh .
LOGDIR=`pwd`/avr-gcc-9-logs GCC_BRANCH=releases/gcc-9 ./gnupru/testing/buildbot-avr.sh .
LOGDIR=`pwd`/avr-gcc-10-logs GCC_BRANCH=releases/gcc-10 ./gnupru/testing/buildbot-avr.sh .
LOGDIR=`pwd`/pru-gcc-10-logs GCC_BRANCH=releases/gcc-10 ./gnupru/testing/buildbot-pru.sh .
GCC_BRANCH=master ./gnupru/testing/buildbot-avr.sh .
