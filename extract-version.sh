#!/bin/bash

# Pattern works for binutils, GCC and gnuprumcu release filenames.
grep -o "${1}-[0-9\.]\+[0-9]" download-and-prepare.sh | head -1 | cut -f2- -d-
