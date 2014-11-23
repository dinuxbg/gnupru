# Testing the pru-gcc toolchain

## Binutils
Go to the binutils build directory and do:
	make check-gas

## GCC
Install Dejagnu:
	apt-get install dejagnu

Then copy the PRU configuration provided with this package:
	sudo cp pru-sim.exp /usr/share/dejagnu/baseboards/

Finally go to the GCC build directory and run the GCC test suite:
	make check-gcc-c RUNTESTFLAGS=--target_board=pru-sim
