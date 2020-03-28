# Testing the pru-gcc toolchain

##  DejaGnu Configuration
Install Dejagnu:

	sudo apt-get install dejagnu autogen

Or, for Fedora:

	sudo dnf install dejagnu autogen

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
	make check-gcc-c++ RUNTESTFLAGS=--target_board=pru-sim

## Comparing builds for regressions

First, build a reference that we'll compare against:

	cd gcc && git checkout origin/master
	BB_BDIR_PREFIX=base-pru ./gnupru/testing/manual-test-pru.sh .

After that, apply your changes and do the build we'll be testing:

	cd gcc && git checkout my-dev-branch
	./gnupru/testing/manual-test-pru.sh .

Now do the comparison. Example for size:

	GCC_EXEC_PREFIX=`realpath ./pru-opt/pru/lib`/ ./gnupru/testing/compare-all-sizes.py pru

## Checking ABI compatibility
It is possible to run part of the GCC testsuite in an "ABI check" mode. The testsuite will compile object files with different compilers, and then check that functions from one object file can call and get correct return value from the other object file.

To install, first put the clpru.sh script into your PATH. This wrapper script is needed because TI compiler does not follow the standard command line option interface, that is expected by the GCC testsuite.

	ln -s gnupru/testing/clpru.sh $HOME/bin/

To execute the GCC ABI regression test suite against the TI toolchain do:

	# Cleanup (important for incremental checks)
	find . -name site.exp | xargs rm -f
	make check-gcc-c RUNTESTFLAGS="--target_board=pru-sim compat.exp" COMPAT_OPTIONS="[list [list {-O2 -mmcu=sim -mabi=ti -Wl,-lc -Wl,-lgloss -Wl,`pru-gcc -print-libgcc-file-name` -DSKIP_COMPLEX -DSKIP_ATTRIBUTE} {-v3 -O2 --display_error_number --endian=little --hardware_mac=on --symdebug:none -DSKIP_COMPLEX -DSKIP_ATTRIBUTE}]]" ALT_CC_UNDER_TEST=`which clpru.sh`

	# Cleanup and check C++
	find . -name site.exp | xargs rm -f
	make check-gcc-c++ RUNTESTFLAGS="--target_board=pru-sim compat.exp" COMPAT_OPTIONS="[list [list {-O2 -mmcu=sim -DSKIP_COMPLEX -DSKIP_ATTRIBUTE} {-v3 -O2 --display_error_number --endian=little --hardware_mac=on --symdebug:none -DSKIP_COMPLEX -DSKIP_ATTRIBUTE}]]" ALT_CC_UNDER_TEST=`which clpru.sh`

A few notes about the options:
* --hardware_mac=on is needed since GCC does not currently support turning off MAC instruction generation. Please let me know if you see a real usecase for this feature, and I may reconsider.
* --symdebug:none is needed since the binutils linker does not yet support the debug relocations output by TI toolchain.
* -mmcu=sim is needed by the GNU LD to provide sufficient memory for test execution.
* The libgcc is forcefully included with -mabi=ti when performing ABI testing. Libgcc as a whole is not really TI ABI compatible, but the parts used by the testsuite are. Multilib is not an option since GCC PRU port does not support some C constructs when -mabi=ti.
* For C++ we do not pass -mabi=ti since the vptr object tables are 4-byte aligned by TI CGT. Current GCC C++ ABI testsuite does not use C function pointers, which allows us to skip -mabi=ti and increase test coverage.
* ABI test case pr83487 is failing due to a bug in TI CGT. See [CODEGEN-4180](https://e2e.ti.com/support/development_tools/compiler/f/343/t/652777)
* ABI test case struct-by-value-22 is failing due to a bug in TI CGT. Stack space is not allocated for a locally defined structure.

Simplified struct-by-value-22 case:

	extern void tedstvoid(void *);
	void test(int n)
	{
	    struct S { char a[n]; } s;
	    testvoid(&s);
	}
