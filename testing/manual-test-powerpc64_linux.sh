#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

# Simple script for manual building and testing of gcc+glibc ToT.
#

BB_ARCH=powerpc64_linux

CROSS_TARGET=powerpc64-unknown-linux-gnu
LINUX_ARCH=powerpc

# Do not send any email for this session
Mail()
{
  true
}

. `dirname ${0}`/buildbot-cross-linus-template.sh
