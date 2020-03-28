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
        o = tempfile.NamedTemporaryFile(delete=True)
        line = line + " -o " + o.name
        ignored = subprocess.run(line.split(), check=True, capture_output=True)

        szout = subprocess.run( [ self.triplet + "-size", "-A", o.name ],
                text=True, capture_output=True, check=True,
                universal_newlines=True).stdout
        o.close()

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

    """ Dump CSV table for all collected tests.  """
    def dump_csv(self, target):
        with open(target + "-size-comparison.csv", "w") as f:
            for e in self.tests:
                f.write(str(e[0]) + ", " + str(e[1]) + ", "
                        + e[2] + ", \"" + e[3] + "\",\n" )

    """ Dump short summary of data collected so far.  """
    def dump_stats(self):
        log.i("best text diff: {0:d}".format(self.best))
        log.i("worst text diff: {0:d}".format(self.worst))
        log.i("avg text diff: {0:f}".format((self.cumulative_diff / self.n)))

    """ Add one more test entry to our database.  """
    def add(self, bsz, psz, line):
        name = self.line2testname(line)

        log.vraw("\rbase: {0:8d}, tested: {1:8d}, {2}        ".format(bsz, psz, name))

        self.tests.append( (bsz, psz, name, line) )
        self.cumulative_base_size += bsz
        self.n += 1
        diff = psz - bsz;
        self.cumulative_diff += diff
        if self.best > diff:
            self.min = diff
        if self.worst < diff:
            self.worst = diff

""" Represent one target we're doing size comparison for.  """
class Target:
    def __init__(self, name):
        self.target = name
        self.triplet = "unknown-unknown-unknown"
        self.stats = SizeStats()
        self.patterns_to_remove = [
                [ "^Executing on host: ", "" ],
                [ "  *\(timeout.*", "" ],
                # Several consecutive -fdump options could occur,
                # so to avoid overlap do not terminate with a space.
                [ " -fdump[-a-z0-9_]*", "" ],
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

        t = TargetTest(self.target, self.triplet, line)
        bsz, psz = t.test()

        if bsz > 0:
            """ base test is good """
            if psz < 0:
                log.e("\nbase passed, but tested gcc failed: " + line)
            else:
                self.stats.add(bsz, psz, line)

    """ Run the size comparison test for this particular target.  """
    def test(self):
        self.triplet = self.get_triplet()
        log.i("Testing target {0} , triplet {1}".format(self.target, self.triplet))

        base_dir = "base-" + self.target + "-gcc-build/gcc/testsuite/gcc"
        tested_dir = self.target + "-gcc-build/gcc/testsuite/gcc"

        os.makedirs(tested_dir, exist_ok=True)
        if not os.path.exists(os.path.join(tested_dir, "gcc.dg-struct-layout-1")):
            shutil.copytree(os.path.join(base_dir, "gcc.dg-struct-layout-1"),
                            os.path.join(tested_dir, "gcc.dg-struct-layout-1"))

        with open(os.path.join(base_dir, "gcc.log"), "r") as f:
            for l in f:
                self.process_line(l.strip())

        self.stats.dump_stats()
        self.stats.dump_csv(self.target)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--verbose", help="print verbosely while executing",
                        action="store_true")
    parser.add_argument("target", help="target to run comparison for")
    args = parser.parse_args()

    log.verbose = args.verbose
    t = Target(args.target);
    t.test()

    sys.exit(0)

# Main body
if __name__ == '__main__':
    main()
