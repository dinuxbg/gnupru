#!/bin/bash

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
    -v) ARGS="${ARGS} -version";;
    -mmcu=sim) ;;
    *) ARGS="${ARGS} ${1}";;
  esac
  shift
done

${EXEC} ${ARGS} -I${INCDIR}
