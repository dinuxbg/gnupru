# Testing the pru-gcc toolchain

##  DejaGnu Configuration
Install Dejagnu:

	apt-get install dejagnu

Then copy the PRU configuration provided with this package:

	sudo cp pru-sim.exp /usr/share/dejagnu/baseboards/


## Binutils
You need to install pru-gcc via some means, and then do a clean build of binutils. The binutils' configure script requires a pru-gcc to be available when configuring the project, in order to setup the LD tests exercising a target compiler.

To run the tests go to the binutils build directory and do:

	make check RUNTESTFLAGS=--target_board=pru-sim

## GCC
First, newlib must be recompiled in "full" mode. Note that a lot of standard features are stripped by default, in order to save valuable space on the constrained PRU. But for checking compliance, we need them all. Here is an example newlib configuration:

	../newlib/configure --target=pru --prefix=$HOME/bin/pru-gcc -enable-newlib-io-long-long --enable-newlib-io-long-double

To execute the GCC C test suite go to the GCC build directory and run:

	make check-gcc-c RUNTESTFLAGS=--target_board=pru-sim

Note that the C++ testsuite cannot be run due to the enormous C++ core library size. It cannot fit in the maximum possible 64k words of program memory possible in the PRU ISA architecture.
