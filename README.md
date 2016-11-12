# Port of GNU GCC and Binutils for the TI PRU I/O processor.

## Introduction
This is an unofficial GCC/Binutils port for the PRU I/O CPU core that is present in TI Sitara AM33xx SoCs. Older PRU core versions are not supported.

The release is ready for cautious usage. A simulator is used to execute the GCC C regression test suite. Results for this release are:

	# of expected passes		83602
	# of unexpected failures	16
	# of expected failures		109
	# of unsupported tests		2533

There are several examples to get started:
 * Assorted small examples: https://github.com/dinuxbg/pru-gcc-examples
 * GCC port of the TI PRU training: https://github.com/dinuxbg/pru-software-support-package . Make sure to read ReadMe-GCC.txt.

Bug reports should be filed in https://github.com/dinuxbg/gnupru/issues . For general questions please use http://beagleboard.org/Community/Forums .

This project has no relation to the TI PRU C compiler. ABI differences between GCC PRU and TI PRU C are tracked in https://github.com/dinuxbg/gnupru/wiki

## Installing On Debian Jessie
If you are running Beaglebone Debian Jessie image, then installation is simple:

	sudo apt-get update
	sudo apt-get install gcc-pru

For other Debian Jessie images, you'll need to add Robert Nelson's package repository. Open /etc/apt/sources.list and add the following line:

	deb [arch=armhf] http://repos.rcn-ee.com/debian/ jessie main

## Building From Sources
The toolchain is published as a series of patches inside the patches subdirectory. The build scripts are tested on a Debian host, but should work on any recent distro.

You'll need some prerequisites. For a Debian host:

	sudo apt-get install build-essential libmpfr-dev libgmp-dev libmpc-dev texinfo libncurses5-dev bison flex

Then it should be a simple matter of:

	export PREFIX=$HOME/bin/pru-gcc   # Define where to install the toolchain
	./download-and-patch.sh           # Download and patch the sources
	./build.sh                        # Build

## Creating Debian Packages From Scratch
There are experimental scripts for packaging binutils and gcc+newlib.

Installing the prerequisites:

	sudo apt-get install dh-autoreconf libgmp-dev libmpfr-dev libmpc-dev libzip-dev autoconf2.64 lsb-release patchutils

Building and packaging:

	./download-and-patch.sh           # Download and patch the sources
	./package-binutils.sh
	sudo dpkg -i packaging/binutils-pru*.deb
	./package-gcc-newlib.sh
	sudo dpkg -i packaging/gcc-pru*.deb

Testing the output:

	pru-as --version
	pru-gcc --version

## Acknowledgements
 * GCC/Binutils Nios2 port was taken as a base for the PRU port.

## TODO
A few long term tasks:
 * Need to review the GCC function prologue handling. Current code is a direct copy of the Nios2 code. It should be correct but is not efficient for PRU.
 * Investigate feasibility of "packed" register support in GCC. PRU port may have to be rewritten to use "virtual" 8-bit registers in order to allow more efficient variable packing.
