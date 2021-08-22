# Port of GNU GCC and Binutils for the TI PRU I/O processor.

## Table Of Contents

 * [Introduction](#introduction)
 * [Examples](#examples)
 * [Getting The Cross Toolchain](#getting-the-cross-toolchain)
   * [Installing On Beagleboard Debian](#installing-on-beagleboard-debian)
   * [Prebuilt Tarballs](#prebuilt-tarballs)
   * [Building Using Crosstool-ng](#building-using-crosstool-ng)
   * [Building From Sources](#building-from-sources)
 * [Acknowledgements](#acknowledgements)

## Introduction

This is a collection of documentation and build scripts for the GNU toolchain targeting the PRU I/O CPU core present in TI Sitara AM33xx SoCs. Older PRU core versions are not supported.

A simulator is used to execute the GCC C regression [test suite](./testing/README.md). Results are posted daily to https://gcc.gnu.org/pipermail/gcc-testresults/ .

Bug reports should be filed in https://github.com/dinuxbg/gnupru/issues . For general questions please use https://forum.beagleboard.org/ .

This project has no relation to the TI PRU C compiler. ABI differences between GCC PRU and TI PRU C are tracked in https://github.com/dinuxbg/gnupru/wiki

## Examples

There are several examples to get started:
 * Assorted small examples: https://github.com/dinuxbg/pru-gcc-examples
 * Beaglemic PDM microphone array: https://gitlab.com/dinuxbg/beaglemic
 * GCC port of the TI PRU training: https://github.com/dinuxbg/pru-software-support-package . Make sure to read ReadMe-GCC.txt.

## Getting The Cross Toolchain

Several methods to acquire the PRU cross toolchain are listed below, ordered by most convenient first.

### Installing On Beagleboard Debian

If you are running a [Beagleboard Debian Image](https://beagleboard.org/latest-images), then installation is simple:

	sudo apt-get update
	sudo apt-get install gcc-pru

### Prebuilt Tarballs

Latest [releases](https://github.com/dinuxbg/gnupru/releases/latest) provide prebuilt tarballs for `amd64` and `armhf` hosts. Simply download, untar and use them when:

 * You want to cross-compile PRU firmware from AMD64 Linux host.
 * You are using an armhf distribution other than [Beagleboard Debian Image](https://beagleboard.org/latest-images).

### Building Using Crosstool-ng

Recently [crosstool-ng](https://github.com/crosstool-ng/crosstool-ng) acquired pru support. Provided you build top-of-tree `crosstool-ng`, you should be able to:

	$ ct-ng pru
	$ ct-ng build
	$ PATH=$HOME/x-tools/pru-elf/bin:$PATH


### Building From Sources

The custom build scripts are tested on a Debian host, but should work on any recent distro. They are intended to be simple enough, so that they can act as a documentation how to cross-compile a toolchain. They intentionally lack some features:

 * Downloaded source tarballs are not verified.
 * Host binaries are not stripped, leading to bigger host executables sizes. Target firmware size is not affected, though!
 * Code complexity is kept at only about 100 lines of simple `BASH` statements.

Users may find that [Beagleboard Debian Packages](#installing-on-beagleboard-debian), or [prebuilt releases](#prebuilt-tarballs) or [crosstool-ng](#building-using-crosstool-ng) are instead more suitable for production.

You'll need some prerequisites. For a Debian host:

	sudo apt-get install build-essential libmpfr-dev libgmp-dev libmpc-dev texinfo libncurses5-dev bison flex

Alternatively, for a Fedora host:

	sudo dnf install @development-tools g++ mpfr-devel gmp-devel libmpc-devel texinfo texinfo-tex texlive-cm-super* texlive-ec ncurses-devel bison flex

Then it should be a simple matter of:

	export PREFIX=$HOME/bin/pru-gcc   # Define where to install the toolchain
	./download-and-prepare.sh         # Download and prepare the sources
	./build.sh                        # Build

## Acknowledgements

 * GCC/Binutils Nios2 port was taken as a base for the PRU port.
