#!/bin/bash

# Frontend to the proprietary TI compiler. Used for invoking
# the GCC ABI checking test suite.

die()
{
  echo "ERROR: $@"
  exit 1
}

if [ -n ${PRU_CGT} ]
then
  EXEC=${PRU_CGT}/bin/clpru
else
  EXEC=`which clpru`
fi

# Some CGT installations cannot find their own syspath. Go figure.
# So help clpru to find its header files, instead of bothering
# the user with extra options.
EXEC=`realpath ${EXEC}`
[ -x ${EXEC} ] || die "${EXEC} is not executable"
EXEC_DIR=`dirname ${EXEC}`
INCDIR=`realpath ${EXEC_DIR}/../include`

# Convert arguments from "Regular Unix" to "TI" naming. Go figure.
# Hopefully no argument contains spaces.
ARGS=
while [ $# != 0 ]
do
  case ${1} in
    -o) ARGS="${ARGS} --output_file";;
    -v) ARGS="${ARGS} --compiler_revision"; echo -n 'TI clpru ';;
    -w) ARGS="${ARGS} --no_warnings";;
    -fdiagnostics-color=*) ;;
    -mmcu=sim) ;;
    -Wno-psabi) ;;   # Why DejaGnu even passes this flag?
    -fno-diagnostics-show-caret) ;;
    -fno-diagnostics-show-line-numbers) ;;
    -fdiagnostics-urls=never) ;;
    *) ARGS="${ARGS} ${1}";;
  esac
  shift
done

# Zero-length arrays are ok, don't complain.
EXTRA_ARGS=--diag_suppress=1231

# Remove spurious newlines to satisfy DejaGnu (PR other/69006).
${EXEC} ${ARGS} ${EXTRA_ARGS} -I${INCDIR} | sed -e '/^$/d'
