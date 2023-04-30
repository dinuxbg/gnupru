#!/bin/bash

# Given a list of Buildbot Logdir directories, convert them
# to Bunsen [1] tags. Bunsen offers an order of magnitude
# more efficient storage, and more.
#
# [1] git://sourceware.org/git/bunsen.git

die()
{
  echo "ERROR: $@"
  exit 1
}

[ $# -gt 2 ] || die "Usage: $0 TAG GIT-URL LOGDIRS..."

TAG=${1}
shift
DST=`realpath ${1}`
shift

[ -d "${DST}" ] || die "${DST} not found. Please create with 'git init --bare'"
which t-upload-git-push >/dev/null || die "Bunsen not found in PATH!"

LOGDIRS=`realpath $@`

pushd `mktemp -d`
for d in ${LOGDIRS}
do
  rm -f *
  cp "${d}"/* .
  [ -f pass ] || continue

  # For some reason testrun.log was sometimes kept.
  # Remove as it is duplicate of testrun.log.gz.
  rm -f testrun.log

  gunzip *.gz
  DATE_TAG=`basename "${d}"`
  t-upload-git-push "${DST}" bb/${TAG}/${DATE_TAG}  *.log *.sum versions.txt
done
popd
