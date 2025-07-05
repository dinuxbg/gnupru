#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

# Simple script for manual building and testing of gcc+glibc ToT.
#

BB_ARCH=armv8l_linux

CROSS_TARGET=armv8l-unknown-linux-gnueabihf
LINUX_ARCH=arm

# Do not send any email for this session
Mail()
{
  true
}

. `dirname ${0}`/buildbot-cross-linus-template.sh
