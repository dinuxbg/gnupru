#!/bin/bash

set -e
set -x

# --------------- GCC+Newlib ------------------
mkdir -p packaging-build/gcc-pru
pushd packaging-build/gcc-pru

tar --strip-components=1 -xaf ../../src/gcc.tar.gz
tar -xaf ../../src/newlib-cygwin.tar.gz
mv newlib-*/libgloss newlib-*/newlib .
rm -fr newlib-*

cp -Rfp ../../packaging/gcc-pru/debian/ .
debuild -i -us -uc -b

popd
