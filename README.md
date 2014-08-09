# This is a port of the GNU GCC and Binutils to the TI PRU I/O processor.

## Introduction
This is a port of the PRU I/O CPU core that is present in TI Sitara AM33xx SoCs. Older PRU core versions are not supported because, frankly, all I have is a beaglebone.

This initial release is preliminary and just a proof-of-concept. It might have some serious bugs, so be warned. That said, there is a working LED blinking demo :)

This project has no relation to the TI PRU C compiler. ABI differences between GCC PRU and TI PRU C are tracked in https://github.com/dinuxbg/gnupru/wiki

## Building
The toolchain is published as a series of patches inside the patches subdirectory.

See build.sh for an example how to build the toolchain. You'll need some prerequisites:

	sudo apt-get install build-essential libmpfr-dev libgmp-dev libmpc-dev texinfo

Then it should be a simple matter of:

	./build.sh

## Getting started with PRU development
See the example subdirectory for a blinking LED demo. To build the PRU firmware:

	cd example/pru
	make

Then, to build the host loader (running on the beaglebone):

	apt-get install libelf-dev	# Needed by loader for parsing the ELF PRU executables
	cd example/host
	make

Finally, to see a blinking led for 30 second on P9_27:

	modprobe uio_pruss
	echo BB-BONE-PRU-01 > /sys/devices/bone_capemgr.8/slots
	cd example/host
	./out/pload ../pru/out/pru-core0.elf ../pru/out/pru-core1.elf

## Acknowledgements
 * GCC/Binutils Nios2 port was taken as a base for the PRU port.
 * Parts of the AM33xx PRU package have been used for the blinking LED example loader: https://github.com/beagleboard/am335x_pru_package
 * Beagleboard.org test debian image has been used for running the blinking LED example: http://beagleboard.org/latest-images/

## TODO
When not fixing bugs, I intend to work on the following items:
 * Need to review the GCC function prologue handling. Current code is a direct copy of the Nios2 code and might not be correct or optimal for PRU.
 * Look again at the linker port. There's too much code for such a simple CPU.
 * Utilize the MAC instruction in libgcc.
 * Write testcases for GCC, GAS and LD.
 * Port newlib. Write useful macros for PRU-specific functionality.
 * Port GDB.

