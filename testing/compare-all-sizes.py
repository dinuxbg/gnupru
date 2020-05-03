#!/usr/bin/env python3

# Simple script to compare object text segment sizes between a baseline
# reference GCC build and a test GCC build.
#
# This script has been heavily influenced by contrib/compare-all-files from
# GCC's sources.

import sys
import os
import argparse
import shutil
import re
import tempfile
import subprocess

# TODO - add support for per-target options variants.

""" Unified portal for user messages.  """
class Logger:
    def __init__(self):
        self.verbose = False
        self.progress = False
        self.nlines = 0
        self.linei = 0

    def i(self, str):
        print(str)

    def e(self, str):
        print(str)

    def vraw(self, str):
        if self.verbose:
            sys.stdout.write(str)
            sys.stdout.flush()

    def v(self, str):
        if self.verbose:
            print(str)

    def progress_step(self, teststr):
        if self.progress:
            bar = ['-', '\\', '|', '/' ]

            sys.stdout.write("                    \r")
            fmtvals = (bar[self.linei % 4], (self.linei * 100) / self.nlines, teststr)
            sys.stdout.write("[%s][%2d%%] %s, " % fmtvals)
            self.linei += 1
            sys.stdout.flush()

log = Logger()

""" Represent one test from target testsuite.  """
class TargetTest:
    # TODO - cache the base size to avoid repetitive invocation.
    # TODO - perhaps invoke $target-size right from Dejagnu itself and
    # here just scan the output?
    def __init__(self, target, triplet, line):
        self.target = target
        self.triplet = triplet

        self.bline = line
        self.pline = line.replace("base-" + self.target + "-gcc-build",
                                  self.target + "-gcc-build")

    """ Calculate text segment size.  """
    def calc_text_size(self, line):
        handle, tmpname = tempfile.mkstemp()
        os.close(handle)

        line = line + " -o " + tmpname
        log.v("executing: " + line)
        ignored = subprocess.run(line.split(), check=True, capture_output=True)

        szout = subprocess.run( [ self.triplet + "-size", "-A", tmpname ],
                text=True, capture_output=True, check=True,
                universal_newlines=True).stdout

        try:
            os.unlink(tmpname)
        except:
            log.v("failed to remove " + tmpname)

        for s in szout.splitlines():
            items = s.split()
            if items[0] == ".text":
                return int(items[1])

        return None

    """ Run the test and return text sizes for base and tested toolchains.  """
    def test(self):
        try:
            bsz = self.calc_text_size(self.bline)
        except:
            bsz = -1
        try:
            psz = self.calc_text_size(self.pline)
        except:
            psz = -1
        return bsz, psz

""" Collection of per-target size statistics.  """
class SizeStats:
    def __init__(self):
        self.tests = []
        self.n = 0
        self.bfails = 0
        self.pfails = 0
        self.best = sys.maxsize
        self.worst = -sys.maxsize + 1
        self.cumulative_diff = 0
        self.cumulative_base_size = 0

    """ Extract the source file name from test execution command line.  """
    def line2testname(self, line):
        m = re.search('testsuite/[a-zA-Z0-9_./-]+\.c($|[ ])', line)
        if m:
            return m.group(0)
        else:
            return '<unrecognized>'

    """
        Dump CSV table for all collected tests.
        Table is sorted per size difference (first columnt).
    """
    def dump_csv(self, target, full_report):
        with open(target + "-size-comparison.csv", "w") as f:
            for e in sorted(self.tests, key=lambda row: row[0]):
                if (full_report or e[0] != 0):
                    f.write(str(e[0]) + ", "
                            + str(e[1]) + ", "
                            + str(e[2]) + ", "
                            + e[3] + ", \"" + e[4] + "\",\n" )

    """ Dump short summary of data collected so far.  """
    def dump_stats(self):
        log.i("")
        log.i("best text diff: {0:d}".format(self.best))
        log.i("worst text diff: {0:d}".format(self.worst))
        log.i("avg text diff: {0:f}".format((self.cumulative_diff / self.n)))

    """ Record a failure to build with base toolchain.  """
    def add_bfail(self):
        self.bfails += 1
        self.progress_step()

    """ Record a failure to build with DUT toolchain.  """
    def add_pfail(self):
        self.pfails += 1
        self.progress_step()

    """ Add one more test entry to our database.  """
    def add(self, bsz, psz, line):
        name = self.line2testname(line)

        log.vraw("\rbase: {0:8d}, tested: {1:8d}, {2}        ".format(bsz, psz, name))

        self.tests.append( (psz - bsz, bsz, psz, name, line) )
        self.cumulative_base_size += bsz
        self.n += 1
        diff = psz - bsz;
        self.cumulative_diff += diff
        if self.best > diff:
            self.best = diff
        if self.worst < diff:
            self.worst = diff
        self.progress_step()

    def progress_step(self):
        log.progress_step("best: %d, worst: %d, bfails: %d, pfails: %d" % (self.best, self.worst, self.bfails, self.pfails))

""" Represent one target we're doing size comparison for.  """
class Target:
    def __init__(self, target, full_report=False):
        self.target = target
        self.full_report = full_report
        self.triplet = "unknown-unknown-unknown"
        self.stats = SizeStats()
        self.lines = []
        self.nlines = 0
        self.patterns_to_remove = [
                [ "^Executing on host: ", "" ],
                [ "  *\(timeout.*", "" ],
                # Several consecutive -fdump options could occur,
                # so to avoid overlap do not terminate with a space.
                [ " -fdump[-a-z0-9_]*", "" ],
                [ " -S ", " -c " ],
                [ " -{1,2}save-temps ", " " ],
                [ " -o [^ ]*", " -frandom-seed=0 " ] ]
        self.stropts_to_remove = [
                " -fverbose-asm ",
                " -flto ",
                " -frtl-abstract-sequences ",
                " -da " ]

    """ Get target triplet.  """
    def get_triplet(self):
        xgcc = "./" + self.target + "-gcc-build/gcc/xgcc"
        return subprocess.run( [ xgcc, "-dumpmachine" ],
                text=True, capture_output=True, check=True,
                universal_newlines=True).stdout.strip()

    """ Process a single line from DejaGnu log file.  """
    def process_line(self, line):
        # First, filter only the lines containing compiler commands.
        if not line.startswith("Executing on host: "):
            return
        if "xgcc -B" not in line:
            return
        if " -E " in line or " -g" in line or " -print-prog-name=" in line:
            return
        if " -print-file-name=" in line or " -print-multi-directory " in line:
            return
        if " -print-multi-lib" in line:
            return
        # Is O0 interesting when comparing sizes?
        if " -O0 " in line:
            return

        for restr in self.patterns_to_remove:
            p = re.compile(restr[0])
            line = p.sub(restr[1], line, 0)

        for opt in self.stropts_to_remove:
            line = line.replace(opt, " ")

        self.lines.append(line)
        self.nlines += 1

    def target_size_tool_available(self):
        ret = subprocess.run( [ self.triplet + "-size", "--version"] )
        if ret.returncode == 0:
            return True
        else:
            return False

    def execute_test_line(self, line):
        t = TargetTest(self.target, self.triplet, line)
        bsz, psz = t.test()

        if bsz > 0:
            """ base test is good """
            if psz < 0:
                log.e("\nbase passed, but tested gcc failed: " + line)
                self.stats.add_pfail()
            else:
                self.stats.add(bsz, psz, line)
        else:
            self.stats.add_bfail()

    """ Run the size comparison test for this particular target.  """
    def test(self):
        self.triplet = self.get_triplet()
        log.i("Testing target {0} , triplet {1}".format(self.target, self.triplet))

        base_dir = "base-" + self.target + "-gcc-build/gcc/testsuite/gcc"
        tested_dir = self.target + "-gcc-build/gcc/testsuite/gcc"

        if not self.target_size_tool_available():
            log.e("Cannot execute " + self.triplet + "-size")
            return 1

        os.makedirs(tested_dir, exist_ok=True)
        if not os.path.exists(os.path.join(tested_dir, "gcc.dg-struct-layout-1")):
            shutil.copytree(os.path.join(base_dir, "gcc.dg-struct-layout-1"),
                            os.path.join(tested_dir, "gcc.dg-struct-layout-1"))

        log.i("Scanning the log file...")
        with open(os.path.join(base_dir, "gcc.log"), "r") as f:
            #ii = 0;
            for l in f:
                #ii += 1
                #if (ii > 5000):
                #    break
                self.process_line(l.strip())

        log.i("Executing and comparing test cases...")
        log.nlines = self.nlines
        for l in self.lines:
            # TODO - use https://docs.python.org/3/library/concurrent.futures.html
            self.execute_test_line(l)

        self.stats.dump_stats()
        self.stats.dump_csv(target=self.target, full_report=self.full_report)

        return 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--verbose", help="print verbosely while executing",
                        action="store_true")
    parser.add_argument("--progress", help="print progress status during execution",
                        action="store_true")
    parser.add_argument("--full-report", help="include all tests in final CSV, even with same size",
                        action="store_true")
    parser.add_argument("target", help="target to run comparison for")
    args = parser.parse_args()

    log.verbose = args.verbose
    log.progress = args.progress
    t = Target(target=args.target, full_report=args.full_report);

    sys.exit(t.test())

# Main body
if __name__ == '__main__':
    main()
