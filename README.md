# Port of GNU GCC and Binutils for the TI PRU I/O processor.

## Introduction
This is a collection of build scripts for the GCC/Binutils port to the PRU I/O CPU core present in TI Sitara AM33xx SoCs. Older PRU core versions are not supported.

A simulator is used to execute the GCC C regression test suite. Results are posted daily to https://gcc.gnu.org/pipermail/gcc-testresults/ .

There are several examples to get started:
 * Assorted small examples: https://github.com/dinuxbg/pru-gcc-examples
 * Beaglemic PDM microphone array: https://gitlab.com/dinuxbg/beaglemic
 * GCC port of the TI PRU training: https://github.com/dinuxbg/pru-software-support-package . Make sure to read ReadMe-GCC.txt.

Bug reports should be filed in https://github.com/dinuxbg/gnupru/issues . For general questions please use http://beagleboard.org/Community/Forums .

This project has no relation to the TI PRU C compiler. ABI differences between GCC PRU and TI PRU C are tracked in https://github.com/dinuxbg/gnupru/wiki

## Installing On Debian Jessie
If you are running Beaglebone Debian image, then installation is simple:

	sudo apt-get update
	sudo apt-get install gcc-pru

For other Debian armhf images, you'll need to add Robert Nelson's package repository. Open /etc/apt/sources.list and add the following line:

	deb [arch=armhf] http://repos.rcn-ee.com/debian/ buster main

## Building From Sources
The build scripts are tested on a Debian host, but should work on any recent distro.

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
