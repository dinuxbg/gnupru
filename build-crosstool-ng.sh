#!/bin/bash

# Script to build pru-elf cross toolchains for several
# hosts, using crosstool-ng.

set -e

die()
{
  echo "ERROR: $@"
  exit 1
}

[ $# != 2 ] || die "Usage: $0 VERSION"
VERSION=${1}
shift

# Work in the current directory.
WORKSPACE=`pwd`

# Where to get CT from.
CT_GIT=https://github.com/dinuxbg/crosstool-ng
CT_TAG=gnupru-${VERSION}

CT=${WORKSPACE}/opt/bin/ct-ng

#=============================================================================
clean()
{
  # sudo rm -fr $HOME/x-tools/*
  rm -fr .build
  rm -f build.log
  rm -f .config
  rm -fr opt
}

#=============================================================================
# Build crosstool-ng.
build_crosstool_ng()
{
  if ! test -d crosstool-ng
  then
    git clone ${CT_GIT} crosstool-ng
  fi
  pushd crosstool-ng
  # Use the ASIS special version for development purposes.
  if [ "x${VERSION}" != "xASIS" ]
  then
    git checkout ${CT_TAG}
  fi
  popd

  pushd crosstool-ng
  ./bootstrap
  ./configure --prefix=${WORKSPACE}/opt/
  make -j`nproc`
  make install
  popd
}


#=============================================================================

# Replace the EXE symbolic links with equivalent
# BAT files.  For example, remove:
#   pru-gcc.exe -> pru-elf-gcc.exe
# and replace with a BAT file calling the original:
#   pru-gcc.bat
convert_symlink_to_bat()
{
 local dst=${1}
 local src=`realpath ${1}`
 local tool=`basename ${dst} .exe | cut -c5-`
 local new_dst=`dirname ${dst}`/`basename ${dst} .exe`.bat
 rm -f ${dst}
 echo "pru-elf-${tool}.exe %*" > ${new_dst}
}

# Remove the given symbolic link, and replace it
# with a copy of the real file.
dup_symlink_to_file()
{
 local dst=${1}
 local src=`realpath ${1}`
 rm -f ${dst}
 cp -f ${src} ${dst}
}

build_mingw()
{
  # If binfmt is enabled for Wine EXEs, then some toolchain
  # configure scripts get confused. Disable binfmt.
  test -f /proc/sys/fs/binfmt_misc/status || sudo mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
  echo 0 | sudo tee /proc/sys/fs/binfmt_misc/status

  # Build mingw host toolchain.
  ${CT} x86_64-w64-mingw32
  ${CT} build

  # Canadian cross compile.
  ${CT} x86_64-w64-mingw32,pru
  # We must use the mingw we just built.
  PATH=$HOME/x-tools/x86_64-w64-mingw32/bin/:$PATH ${CT} build

  # I'm not sure why crosstool-ng does not install the necessary runtime DLLs.
  # Let's manually copy them.
  chmod +w $HOME/x-tools/HOST-x86_64-w64-mingw32/pru-elf/bin/
  cp $HOME/x-tools/x86_64-w64-mingw32/x86_64-w64-mingw32/sysroot/usr/x86_64-w64-mingw32/bin/libwinpthread-1.dll $HOME/x-tools/HOST-x86_64-w64-mingw32/pru-elf/bin/
  chmod +w $HOME/x-tools/HOST-x86_64-w64-mingw32/pru-elf/libexec/gcc/pru-elf/*
  cp $HOME/x-tools/x86_64-w64-mingw32/x86_64-w64-mingw32/sysroot/usr/x86_64-w64-mingw32/bin/libwinpthread-1.dll $HOME/x-tools/HOST-x86_64-w64-mingw32/pru-elf/libexec/gcc/pru-elf/*/

  # The 7za+Windows combination does not support symbolic links. Perform workarounds.
  chmod -R +w $HOME/x-tools/HOST-x86_64-w64-mingw32/pru-elf/
  find $HOME/x-tools/HOST-x86_64-w64-mingw32/pru-elf -type l -a -iname "*.exe" | while read F; do convert_symlink_to_bat ${F}; done
  find $HOME/x-tools/HOST-x86_64-w64-mingw32/pru-elf -type l -a -iname "*.dll" | while read F; do dup_symlink_to_file ${F}; done

  # Finally - we can package.
  pushd $HOME/x-tools/HOST-x86_64-w64-mingw32/
  7za a -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on ${WORKSPACE}/pru-elf-${VERSION}.windows.EXPERIMENTAL.7z pru-elf/
  popd
}

build_arm()
{
  local tarname=pru-elf-${VERSION}.arm.tar

  ${CT} arm-unknown-linux-gnueabihf
  ${CT} build
  ${CT} arm-unknown-linux-gnueabihf,pru
  PATH=$HOME/x-tools/arm-unknown-linux-gnueabihf/bin/:$PATH ${CT} build

  rm -f ${tarname}*
  tar -C $HOME/x-tools/HOST-arm-unknown-linux-gnueabihf/ -caf ${tarname} pru-elf
  xz -9 ${tarname}
}

build_x86()
{
  local tarname=pru-elf-${VERSION}.amd64.tar

  ${CT} x86_64-unknown-linux-gnu
  ${CT} build
  ${CT} x86_64-unknown-linux-gnu,pru
  PATH=$HOME/x-tools/x86_64-unknown-linux-gnu/bin/:$PATH ${CT} build

  rm -f ${tarname}*
  tar -C $HOME/x-tools/HOST-x86_64-unknown-linux-gnu/ -caf ${tarname}  pru-elf
  xz -9 ${tarname}
}

#=============================================================================
build_crosstool_ng
build_arm
build_x86
build_mingw

echo ""
echo SUCCESS
