#!/bin/bash

set -e
set -x

# apt install bison flex gettext texinfo binutils gcc debhelper tar findutils autotools-dev dh-autoreconf

# --------------- Binutils ------------------
mkdir -p packaging-build/binutils-pru
pushd packaging-build/binutils-pru

tar --strip-components=1 -xaf ../../src/binutils-gdb.tar.gz
cp -Rfp ../../packaging/binutils-pru/debian/ .
debuild -i -us -uc -b

popd
