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

	../newlib/configure --target=pru --prefix=$HOME/bin/pru-gcc -enable-newlib-io-long-long --enable-newlib-io-long-double --enable-newlib-io-c99-formats

To execute the GCC C test suite go to the GCC build directory and run:

	make check-gcc-c RUNTESTFLAGS=--target_board=pru-sim

Note that the C++ testsuite cannot be run due to the enormous C++ core library size. It cannot fit in the maximum possible 64k words of program memory possible in the PRU ISA architecture.

## Checking ABI compatibility
It is possible to run part of the GCC testsuite in an "ABI check" mode. The testsuite will compile object files with different compilers, and then check that functions from one object file can call and get correct return value from the other object file.

To install, first put the clpru.sh script into your PATH. This wrapper script is needed because TI compiler does not follow the standard command line option interface, that is expected by the GCC testsuite.

	ln -s gnupru/testing/clpru.sh $HOME/bin/

To execute the GCC ABI regression test suite against the TI toolchain do:

	# Cleanup (important for incremental checks)
	find . -name site.exp | xargs rm -f
	make check-gcc-c RUNTESTFLAGS="--target_board=pru-sim compat.exp" COMPAT_OPTIONS="[list [list {-O2 -mmcu=sim -mabi=ti -lc -lgloss `pru-gcc -print-libgcc-file-name` -DSKIP_COMPLEX -DSKIP_ATTRIBUTE} {-v3 -O2 --display_error_number --endian=little --hardware_mac=on --symdebug:none -DSKIP_COMPLEX -DSKIP_ATTRIBUTE}]]" ALT_CC_UNDER_TEST=`which clpru.sh`

A few notes about the options:
* --hardware_mac=on is needed since GCC does not currently support turning off MAC instruction generation. Please let me know if you see a real usecase for this feature, and I may reconsider.
* --symdebug:none is needed since the binutils linker doest not yet support the debug relaxations output by TI toolchain.
* -mmcu=sim is needed by the GNU LD to provide sufficient memory for test execution.
* The libgcc is forcefully included with -mabi=ti when performing ABI testing. Libgcc as a whole is not really TI ABI compatible, but the parts used by the testsuite are. Multilib is not an option since GCC PRU port does not support some C constructs when -mabi=ti.
