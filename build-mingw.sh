#!/bin/bash

# EXPERIMENTAL script to build pru-elf cross compiler,
# which runs on Windows hosts.

CT_GIT=https://github.com/dinuxbg/crosstool-ng
CT_TAG=gnupru-2021.10.mingw

# Work in the current directory.
WORKSPACE=`pwd`

set -e

#=============================================================================
# Build crosstool-ng.
if ! test -d crosstool-ng
then
  git clone ${CT_GIT} crosstool-ng
  pushd crosstool-ng
  git checkout ${CT_TAG}
  popd
fi
pushd crosstool-ng
./bootstrap
./configure --prefix=${WORKSPACE}/ct-ng/
make -j`nproc`
make install
popd

CT=${WORKSPACE}/ct-ng//bin/ct-ng

#=============================================================================
# If binfmt is enabled for Wine EXEs, then some toolchain
# configure scripts get confused. Disable binfmt.
test -f /proc/sys/fs/binfmt_misc/status || sudo mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
echo 0 | sudo tee /proc/sys/fs/binfmt_misc/status

#=============================================================================
# Build mingw host toolchain.
${CT} x86_64-w64-mingw32
${CT} build

# We must use the mingw we just built.
export PATH=$HOME/x-tools/x86_64-w64-mingw32/bin/:$PATH

#=============================================================================
# Canadian cross compile.
${CT} x86_64-w64-mingw32,pru
${CT} build

#=============================================================================
# I'm not sure why crosstool-ng does not install the necessary runtime DLLs.
# Let's manually copy them.
chmod +w ~/x-tools/HOST-x86_64-w64-mingw32/pru-elf/bin/
cp ~/x-tools/x86_64-w64-mingw32/x86_64-w64-mingw32/sysroot/usr/x86_64-w64-mingw32/bin/libwinpthread-1.dll ~/x-tools/HOST-x86_64-w64-mingw32/pru-elf/bin/
chmod +w ~/x-tools/HOST-x86_64-w64-mingw32/pru-elf/libexec/gcc/pru-elf/*
cp ~/x-tools/x86_64-w64-mingw32/x86_64-w64-mingw32/sysroot/usr/x86_64-w64-mingw32/bin/libwinpthread-1.dll ~/x-tools/HOST-x86_64-w64-mingw32/pru-elf/libexec/gcc/pru-elf/*/

#=============================================================================
# Finally - we can package.
pushd ~/x-tools/HOST-x86_64-w64-mingw32/
7za a -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on ${WORKSPACE}/pru-elf-mingw.EXPERIMENTAL.7z pru-elf/
popd

#=============================================================================
echo ""
echo SUCCESS
