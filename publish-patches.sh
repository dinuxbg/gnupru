#!/bin/bash

# Script for maintainer's use only. You likely do not need to run it.
#
# Scan the local source trees and add all non-mainlined PRU patches
# to the gnupru project structure.

die()
{
  echo "ERROR: $@"
  exit 1
}

[ -d gnupru ] || die "run from the local TOP tree"

replace_var()
{
  local script=$1
  local commit_var=$2
  local commit=$3
  local t=`tempfile`

  cat ${script} | sed -e "s/^${commit_var}=.\+/${commit_var}=${commit}/g" > ${t} || die
  cat ${t} > ${script} || die
  rm -f ${t}
}

extract_patches()
{
  local srcdir=$1
  local COMMIT_VAR=$2
  local WORKDIR=`pwd`

  pushd ${srcdir}
  git status | grep modified: && die "${srcdir} has local modifications"
  local COMMIT=`git rev-parse origin/master`
  replace_var ${WORKDIR}/gnupru/download-and-patch.sh ${COMMIT_VAR} ${COMMIT}
  /bin/mv 00* /tmp/
  git format-patch origin/master
  (cd ${WORKDIR}/gnupru/patches && git rm -fr ${srcdir} && mkdir ${srcdir})
  mv 00* ${WORKDIR}/gnupru/patches/${srcdir}/ || die
  (cd ${WORKDIR}/gnupru/ && git add patches/${srcdir} download-and-patch.sh)
  popd
}

extract_patches binutils-gdb BINUTILS_BASECOMMIT
extract_patches gcc GCC_BASECOMMIT
extract_patches newlib-cygwin NEWLIB_BASECOMMIT
