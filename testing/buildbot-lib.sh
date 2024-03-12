# SPDX-License-Identifier: GPL-3.0-or-later

# Simple automation helpers for daily testing of GNU toolchain.
#
# List of global variables:
#   WORKSPACE
#   LOGDIR
#   PREFIX

# Print error and exit.
error()
{
  echo "ERROR: $@"
  exit 1
}

# Print a large sign in log.
print_stage()
{
  echo "*******************************************************************************"
  echo "*"
  echo "* $@"
  echo "*"
  echo "*******************************************************************************"
}

# Clone if needed, and update a GIT project to latest upstream.
#   PRJ    : Which GIT project to update.
#   URL    : Which URL to use for initial clone.
#   BRANCH : Which upstream branch to checkout.
bb_update_source()
{
  local PRJ=${1}
  local URL=${2}
  local BRANCH=${3:-master}
  local P
  local C

  print_stage "Updating GIT source tree for ${PRJ}"

  pushd ${WORKSPACE}

  [ -d "${PRJ}" ] || git clone ${URL} ${PRJ} || error "initial ${URL} clone failed"

  pushd ${PRJ} || error "cannot enter ${PRJ}"
  git remote prune origin || error "failed to prune remote"
  git am --abort
  git merge --abort
  git rebase --abort
  git reset --hard HEAD
  git clean -f -d -x
  git fetch origin || error "failed to sync ${PRJ}"
  git checkout origin/${BRANCH} || error "failed to checkout ${PRJ}"

  C=`git rev-parse HEAD`
  echo "${PRJ} ${C}" >> ${LOGDIR}/${BUILD_TAG}/versions.txt

  # Apply any out-of-tree patches.
  [ -d ../${PRJ}-patches ] && ls ../${PRJ-}-patches/* | sort | while read P
  do
    git am -3 ${P} || error "failed to apply ${P}"
    echo "${PRJ} ${P}" >> ${LOGDIR}/${BUILD_TAG}/versions.txt
  done

  popd
  popd
}

# Prepare tree for release, and write proper versioning info.
#
# Follow contrib/gcc_update's behaviour for filling in version
# information in places the test and build systems expect it.
#
# BRANCH : gcc branch we have checked out
bb_gcc_touch_source_tree()
{
  local BRANCH=${1}
  local C

  pushd ${WORKSPACE}/gcc || error "failed to enter gcc"

  LC_ALL=C ./contrib/gcc_update origin -r `git rev-parse HEAD`

  popd
}

# Clean workspace for the currently selected target.
bb_clean()
{
  print_stage "Cleaning all projects"
  local BDIR
  for BDIR in `ls -d ${WORKSPACE}/${BB_BDIR_PREFIX}-*-build`
  do
    rm -fr ${BDIR}
  done
  rm -fr ${PREFIX}
}

# Invoke the ./configure script for project PRJ. Rest of function arguments
# are passed on to configure.
bb_config()
{
  local PRJ="${1}"
  shift
  local CONFIG_PARAMS="$@"
  local CONFIGURE

  print_stage "Configuring ${PRJ} with parameters \"${CONFIG_PARAMS}\""
  mkdir -p ${WORKSPACE}/${BB_BDIR_PREFIX}-${PRJ}-build
  pushd ${WORKSPACE}/${BB_BDIR_PREFIX}-${PRJ}-build || error "failed to mkdir $${BB_BDIR_PREFIX}-{PRJ}-build"

  # HACK: Workaround bug in newlib testsuite's build system.
  # See: https://sourceware.org/ml/newlib/2011/msg00457.html
  CONFIGURE=`realpath ${WORKSPACE}/${PRJ}/configure`

  ${CONFIGURE} --prefix=${PREFIX} ${CONFIG_PARAMS} || error "Could not configure ${PRJ}"

  popd
}

# Invoke "make" in the build directory for the already-configured
# given project.
#
# Rest of function arguments are passed on to "make".
bb_make()
{
  local IGNORE_ERRORS=false
  [ "${1}" = "--ignore-errors" ] && { IGNORE_ERRORS=true; shift; }
  local PRJ="${1}"
  shift
  local MAKE_PARAMS="$@"

  print_stage "Invoking make for ${PRJ} with parameters \"${MAKE_PARAMS}\""
  mkdir -p ${WORKSPACE}/${BB_BDIR_PREFIX}-${PRJ}-build
  pushd ${WORKSPACE}/${BB_BDIR_PREFIX}-${PRJ}-build || error "missing ${BB_BDIR_PREFIX}-${PRJ}-build"

  make ${MAKE_PARAMS} || { [ ${IGNORE_ERRORS} = false ] &&  error "Could not make ${PRJ}"; }

  popd
}

# Some projects have weird in-tree build rules.
#
# Use this helper function to execute arbitrary commands in the
# given project's source directory.
bb_source_command()
{
  local PRJ="${1}"
  shift
  local CMDS="$@"

  print_stage "Running custom command \"${CMDS}\" in project ${PRJ}"
  pushd ${WORKSPACE}/${PRJ} || error "missing ${PRJ}"

  ${CMDS} || error "Could not build ${PRJ}"

  popd
}

# Generate email subject string for a detected test case regression.
regression_email_subject()
{
  local LOGFILE=${1}

  local TARGET=`cat ${LOGFILE} | awk '/Target is/ {print $3; exit}'`

  echo "[BUILDBOT] Regression detected for ${TARGET}"
}

# Send email for a detected test case regression.
bb_email_regression()
{
  local BUILD_TAG=${1}
  local LOGFILE=${LOGDIR}/${BUILD_TAG}/regression.log

  print_stage "Sending email for detected regression."

  # Note: Usually you want to install heirloom-mailx, instead of relying
  # on the bsd-mailx default package.

  cat ${LOGFILE} | Mail -s "`regression_email_subject ${LOGFILE}`" ${REGRESSION_RECIPIENTS}
}

# Send an email for a detected build failure.
bb_email_build_failure()
{
  local BUILD_TAG=${1}
  local LOGFILE=${2}

  # Do not call print_stage here.
  # Output is not being collected to build log at this stage.
  zcat ${LOGFILE} | tail -200 | Mail -s "[BUILDBOT] Build ${BUILD_TAG} failed" ${REGRESSION_RECIPIENTS}
}

# Gather all log files from all build directories and place
# them in the dedicated log directory for this particular test run.
#
# We are interested in all *.sum and their *.log counterparts.
# *.log files are compressed to save space.
bb_gather_log_files()
{
  local BUILD_TAG=${1}
  local F

  print_stage "Gathering log files"

  find `ls -d ${WORKSPACE}/${BB_BDIR_PREFIX}-*-build` -name "*.sum" | while read F
  do
    cp ${F} ${LOGDIR}/${BUILD_TAG}/ || error "failed to copy ${F}"
    local L=`dirname ${F}`/`basename ${F} .sum`.log
    cp ${L} ${LOGDIR}/${BUILD_TAG}/ || error "failed to copy ${L}"
    gzip -9 ${LOGDIR}/${BUILD_TAG}/`basename ${L}`
  done
}

# Call this after all sum files have been collected into the
# daily build's log directory.
#
# Function invokes GCC's contrib scripts to check summary files
# between last good run and current run, so that test case regressions
# can be detected.
bb_check_for_regressions()
{
  local PREV_BUILD_TAG=${1}
  local BUILD_TAG=${2}

  print_stage "Checking log files for regressions since the last run"

  # Compare to previous build.  If there are regressions, send an email.
  ( local sum
    for sum in ${LOGDIR}/${BUILD_TAG}/*.sum
    do
      echo "========================= `basename ${sum} .sum` ========================="
      ${WORKSPACE}/gcc/contrib/dg-cmp-results.sh ""         \
	      ${LOGDIR}/${PREV_BUILD_TAG}/`basename ${sum}` \
	      ${sum}
    done
  ) > ${LOGDIR}/${BUILD_TAG}/regression.log
  grep '.*->.*: .*' ${LOGDIR}/${BUILD_TAG}/regression.log && bb_email_regression ${BUILD_TAG}
  return 0
}

# This must be the first called function from the main script.
# It initializes the current test run directory and sets
# the environment.
bb_init()
{
  [ $# == 1 ] || error "usage: $0 <WORKSPACE>"

  [ -z ${BB_ARCH} ] && error "Please define BB_ARCH"
  BB_BDIR_PREFIX=${BB_BDIR_PREFIX:-${BB_ARCH}}

  WORKSPACE=`realpath "${1}"`
  [ -d "$WORKSPACE" ] || error "$WORKSPACE is not a directory"

  PREFIX=${PREFIX:-${WORKSPACE}/${BB_ARCH}-opt}
  mkdir -p ${PREFIX}
  LOGDIR=${LOGDIR:-${WORKSPACE}/${BB_ARCH}-logs}
  mkdir -p ${LOGDIR}
}

# Call this from the main script to do the actual build, test and report.
bb_daily_build()
{
  cd $WORKSPACE

  local BUILD_TAG=`date +%Y%m%d-%H%M`
  mkdir -p ${LOGDIR}/${BUILD_TAG} || error "failed to create log directory for ${BUILD_TAG}"

  # Check what is the previous one.
  # First time let's compare with ourselves.
  local PREV_BUILD_TAG=`cd ${LOGDIR} && dirname $( { ls */pass 2>/dev/null || echo ${BUILD_TAG}/pass ; } | sort | tail -1)`
  [ -z ${PREV_BUILD_TAG} ] && error "failed to determine previous successful build"

  # Execute in a subshell in order to catch build errors and send an email.
  ( set -x; set -o pipefail; time bb_daily_target_test ${PREV_BUILD_TAG} ${BUILD_TAG} |& gzip - >${LOGDIR}/${BUILD_TAG}/build.log.gz ) 2>/dev/null
  ST=$?
  [ "${ST}" = "0" ] || bb_email_build_failure ${BUILD_TAG} ${LOGDIR}/${BUILD_TAG}/build.log.gz
  [ "${ST}" = "0" ] && touch ${LOGDIR}/${BUILD_TAG}/pass

  # Also add it to the Bunsen GIT. Make it optional, for now.
  local LOGDIR_BASE=`basename ${LOGDIR}`
  local BUNSEN_TAG=`echo ${LOGDIR_BASE} | sed -e 's@\([a-z0-9_-]\+\)-logs@\1@g'`
  ${WORKSPACE}/gnupru/testing/logdir2bunsen.sh ${BUNSEN_TAG} ${WORKSPACE}/buildbot-logs.git ${LOGDIR}/${BUILD_TAG} || echo "FAILED TO PUSH TO BUNSEN GIT"

  exit ${ST}
}
