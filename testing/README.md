# Testing the pru-gcc toolchain

Regression testing is one of the methods to avoid [Compiler Writer's Deadly Sin #13](https://gcc.gnu.org/wiki/DeadlySins).

Listed below are instructions to setup the necessary environment and to run regression tests for the PRU GNU toolchain.

## Table Of Contents
 * [Setting Up The Environment](#setting-up-the-environment)
   * [DejaGnu Configuration](#dejagnu-configuration)
 * [The BuildBot Scripts](#the-buildbot-scripts)
 * [Internals Of Cross-Toolchain Testing](#internals-of-cross-toolchain-testing)
   * [Binutils](#binutils)
   * [GCC](#gcc)
   * [Comparing builds for test failure regressions](#comparing-builds-for-test-failure-regressions)
   * [Comparing builds for size regressions](#comparing-builds-for-size-regressions)
   * [Checking ABI compatibility](#checking-abi-compatibility)

## Setting Up The Environment
###  DejaGnu Configuration

Install DejaGnu:

	sudo apt-get install dejagnu autogen

Or, for Fedora:

	sudo dnf install dejagnu autogen

DejaGnu versions 1.6.3 and later include the necessary PRU simulator configuration.  If you have an older version, you can manually download and install the config file:

	wget 'http://git.savannah.gnu.org/gitweb/?p=dejagnu.git;a=blob_plain;f=baseboards/pru-sim.exp;hb=HEAD' -O pru-sim.exp
	sudo cp pru-sim.exp /usr/share/dejagnu/baseboards/

## The BuildBot Scripts

All the steps for testing and finding regressions in PRU toolchain have been automated with a simple set of scripts. See the [BuildBot](./BUILDBOT.md) section for instructions how to run those scripts on your computer.

Those exact same scripts are used to generate the reports for https://gcc.gnu.org/pipermail/gcc-testresults/ , and also to raise warnings about newly introduced test failures.

## Internals Of Cross-Toolchain Testing

I understand that the [BuildBot](./BUILDBOT.md) set of scripts might be too much `BASH` for some. Below I have captured more human-readable documentation for running cross toolchain regression tests.

### Binutils
You need to install pru-gcc via some means, and then do a clean build of binutils. The binutils' configure script requires a pru-gcc to be available when configuring the project, in order to setup the LD tests exercising a target compiler.

To run the tests go to the binutils build directory and do:

	make check RUNTESTFLAGS=--target_board=pru-sim

### GCC
First, newlib must be recompiled in "full" mode. Note that a lot of standard features are stripped by default, in order to save valuable space on the constrained PRU. But for checking compliance, we need them all. Here is an example newlib configuration:

	../newlib/configure --target=pru --prefix=$HOME/bin/pru-gcc -enable-newlib-io-long-long --enable-newlib-io-long-double --enable-newlib-io-c99-formats

To execute the GCC C test suite go to the GCC build directory and run:

	make check-gcc-c RUNTESTFLAGS=--target_board=pru-sim
	make check-gcc-c++ RUNTESTFLAGS=--target_board=pru-sim

The full regression test might take over an hour to execute. For development you may also run a small subset of it, e.g.:

	make check-gcc-c RUNTESTFLAGS="--target_board=pru-sim pru.exp="

### Comparing builds for test failure regressions

Let's say you have built and checked GCC twice - once with an old and then with a new version of GCC sources. The GCC sources include a helpful script to analyse the test results and report tests which passed in the *old* but failed with the *new* version of GCC:

	gcc/contrib/dg-cmp-results.sh "" results-old/gcc.sum results-new/gcc.sum

### Comparing builds for size regressions

First, build and test the reference that we'll compare against:

	cd gcc && git checkout origin/master
	BB_BDIR_PREFIX=base-pru ./gnupru/testing/manual-test-pru.sh .

After that, apply your changes and do the build we'll be testing:

	cd gcc && git checkout my-dev-branch
	./gnupru/testing/manual-build-pru.sh .

Now do the comparison. Example for size:

	GCC_EXEC_PREFIX=`realpath ./pru-opt/pru/lib`/ ./gnupru/testing/compare-all-sizes.py pru

### Checking ABI compatibility
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
