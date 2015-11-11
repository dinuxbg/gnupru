# Testing the pru-gcc toolchain

## Binutils
Go to the binutils build directory and do:

	make check-gas
	make check-ld

## GCC
First, newlib must be recompiled in "full" mode. Note that a lot of standard features are stripped by default, in order to save valuable space on the constrained PRU. But for checking compliance, we need them all. Here is an example newlib configuration:

	../newlib/configure --target=pru --prefix=$HOME/bin/pru-gcc -enable-newlib-io-long-long --enable-newlib-io-long-double

Install Dejagnu:

	apt-get install dejagnu

Then copy the PRU configuration provided with this package:

	sudo cp pru-sim.exp /usr/share/dejagnu/baseboards/

Finally go to the GCC build directory and run the GCC test suite:

	make check-gcc-c RUNTESTFLAGS=--target_board=pru-sim
