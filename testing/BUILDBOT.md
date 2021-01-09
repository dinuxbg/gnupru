# Naive Build Bot For GCC Cross Toolchain Testing

# Goals
 1. Automatically establish a workspace. First run of the bot should just work, without lengthy download and "mkdir/cd" instructions.
 2. Download, build and test all parts of the toolchain - binutils, GCC, libc, simulator.
 3. Optionally download needed sources. Daily builds need to test top-of-tree, whereas tracking regressions require manually provided source tree.
 4. Optionally run binutils/gcc/libc tests and save the logs.
 5. Detect regressions since the last run.
 6. Optionally send emails for test results and/or regressions.
 7. Support multiple targets in a single workspace. This save disk space.

# Non-Goals
 1. Stick to simple shell scripts. Reuse gcc/contrib scripts for log analysis.
 2. No dashboards, UI, remote worker machines, or docker containers.

#  Mail Configuration
The ```Mail``` command line tool must be present and configured to be able to send email. Buildbot sends test summaries and regression reports via email.

Example for Debian:

	sudo apt install mailx
	vim ~/.mailrc
	# Fill-in your SMTP configuration.

#  Installation
See the crontest.sh for an example script that you execute from a crontab job.

# Phases Of The BuildBot

## Setup
Each top-level script starts with loading helper library functions and calling bb_init.

	. `dirname ${0}`/buildbot-lib.sh
	bb_init ${@}

## Start
Actual work starts from the top-level script with:

	bb_daily_build

## Update Sources
TODO

## GCC Version Update
For top-of-tree GCC, we need to call ```./contrib/gcc_update``` in order to embed a readable version in gcc test restuls.

## AVR Dejagnu Setup
TODO

## Config And Build Binutils
TODO

## Config And Build GCC - Stage 1
TODO

## Config And Build Newlib
TODO

## Config And Build GCC - Stage 2
TODO

## Build Simulator
TODO

## Run Tests
TODO

## Gather Log Files
TODO

## Optionally Email Results
TODO

## Optionally Email Regressions, If Found
TODO

# References
 1. The proper full-featured [GCC buildbot](https://github.com/LinkiTools/gcc-buildbot/).
 2. Avrtest [project](https://sourceforge.net/p/winavr/code/HEAD/tree/trunk/avrtest/).
 3. AVR testing [notes](https://lists.gnu.org/archive/html/avr-gcc-list/2009-09/msg00016.html).
 4. Generic GCC testing [notes](https://gcc.gnu.org/wiki/Testing_GCC).
