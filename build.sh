#!/bin/bash

# Sample script to build the GCC PRU toolchain.

MAINDIR=`pwd`
SRC=`pwd`/src
BUILD=`pwd`/build

die()
{
  echo ERROR: $@
  exit 1
}

build_binutils()
{
  cd $BUILD/binutils-gdb
  $SRC/binutils-gdb/configure --target=pru --prefix=$PREFIX --disable-nls --with-bugurl="https://github.com/dinuxbg/gnupru/issues" --disable-gdb || die Could not configure Binutils
  make -j`nproc` || die Could not build Binutils
  make install || die Could not install Binutils
}


build_gcc_pass()
{
  PASS=$1
  EXTRA_ARGS=$2
  cd $BUILD/gcc
  $SRC/gcc/configure --target=pru --prefix=$PREFIX --disable-nls --with-newlib --with-bugurl="https://github.com/dinuxbg/gnupru/issues" $EXTRA_ARGS || die Could not configure GCC pass$PASS
  make -j`nproc` || die Could not build GCC pass$PASS
  make install || die Could not install GCC pass$PASS
}

build_newlib()
{
  cd $BUILD/newlib-cygwin
  $SRC/newlib-cygwin/configure --target=pru --prefix=$PREFIX --disable-newlib-fvwrite-in-streamio --enable-newlib-nano-formatted-io --disable-newlib-multithread || die Could not configure Newlib
  make -j`nproc` || die Could not build Newlib
  make install || die Could not install Newlib
}

build_gnuprumcu()
{
  cd $BUILD/gnuprumcu
  $SRC/gnuprumcu/configure --target=pru --prefix=$PREFIX || die Could not configure gnuprumcu
  make -j`nproc` || die Could not build gnuprumcu
  make install || die Could not install gnuprumcu
}

RETDIR=`pwd`

export PATH=$PREFIX/bin:$PATH
die "This is development tree. Please use the master branch"

[ -d $SRC ] || die $SRC does not exist. Please run ./download-and-patch.sh
[ -z "$PREFIX" ] && die Please \"export PREFIX=...\" to define where to install the toolchain
mkdir -p $PREFIX
[ -d "$PREFIX" ] || die Could not create installation target directory "$PREFIX"
mkdir -p $BUILD/gcc
mkdir -p $BUILD/binutils-gdb
mkdir -p $BUILD/newlib-cygwin
mkdir -p $BUILD/gnuprumcu

# Configure, build and install.
build_binutils
build_gcc_pass 1 "--without-headers --enable-languages=c"
build_newlib
build_gcc_pass 2 "--enable-languages=c,c++"
build_gnuprumcu

cd $RETDIR

echo Done.
