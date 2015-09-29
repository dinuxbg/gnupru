# Port of GNU GCC and Binutils for the TI PRU I/O processor.

## Introduction
This is an unofficial GCC/Binutils port for the PRU I/O CPU core that is present in TI Sitara AM33xx SoCs. Older PRU core versions are not supported.

The release is ready for cautious usage. There are several small examples in https://github.com/dinuxbg/pru-gcc-examples . A simulator is used to execute the GCC C regression test suite. Results for this release are:

	# of expected passes           81497
	# of unexpected failures       31
	# of unexpected successes      1
	# of expected failures	       97
	# of unsupported tests	       1974

Bug reports should be filed in https://github.com/dinuxbg/gnupru/issues . For general questions please use http://beagleboard.org/Community/Forums .

This project has no relation to the TI PRU C compiler. ABI differences between GCC PRU and TI PRU C are tracked in https://github.com/dinuxbg/gnupru/wiki

## Building
The toolchain is published as a series of patches inside the patches subdirectory. The build scripts are tested on a Debian host, but should work on any recent distro.

You'll need some prerequisites. For a Debian host:

	sudo apt-get install build-essential libmpfr-dev libgmp-dev libmpc-dev texinfo libncurses5-dev

Then it should be a simple matter of:

	export PREFIX=$HOME/bin/pru-gcc   # Define where to install the toolchain
	./download-and-patch.sh           # Download and patch the sources
	./build.sh                        # Build

## Acknowledgements
 * GCC/Binutils Nios2 port was taken as a base for the PRU port.

## TODO
I intend to scratch my itch on the following items:
 * Need to review the GCC function prologue handling. Current code is a direct copy of the Nios2 code. It should be correct but is not efficient for PRU.
 * Look again at the linker port. There's too much code for such a simple CPU.
 * Write testcases for GCC, GAS and LD.
 * Make a debian package.
 * Port GDB.

