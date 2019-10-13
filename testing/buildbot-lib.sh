

# Simple automation helpers for daily testing of GNU toolchain.
#
# List of global variables:
#   WORKSPACE
#   LOGDIR
#   PREFIX

error()
{
  echo "ERROR: $@"
  exit 1
}

print_stage()
{
  echo "*******************************************************************************"
  echo "*"
  echo "* $@"
  echo "*"
  echo "*******************************************************************************"
}

bb_update_source()
{
  local PRJ=${1}
  local URL=${2}
  local P

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
  git checkout origin/master || error "failed to checkout ${PRJ}"
  [ -d ../${PRJ}-patches ] && ls ../${PRJ-}-patches/* | sort | while read P
  do
    git am -3 ${P} || error "failed to apply ${P}"
  done
  git tag buildbot-daily-${BUILD_TAG}

  popd
  popd
}

bb_update_source_svn()
{
  local PRJ=${1}
  local URL=${2}
  local P

  pushd ${WORKSPACE}

  [ -d "${PRJ}" ] || svn co ${URL} ${PRJ} || error "initial ${URL} clone failed"

  pushd ${PRJ} || error "cannot enter ${PRJ}"
  svn revert --recursive . || error "failed to prune remote"
  svn update || error "failed to update SVN ${PRJ}"
  [ -d ../${PRJ}-patches ] && ls ../${PRJ-}-patches/* | sort | while read P
  do
    echo "ERROR: Local patching not supported for SVN. Sorry"
    exit 1
  done

  popd
  popd
}

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

bb_make()
{
  local IGNORE_ERRORS=false
  [ "${1}" = "--ignore-errors" ] && { IGNORE_ERRORS=true; shift; }
  local PRJ="${1}"
  shift
  local MAKE_PARAMS="$@"

  print_stage "Building ${PRJ} with parameters \"${CONFIG_PARAMS}\""
  mkdir -p ${WORKSPACE}/${BB_BDIR_PREFIX}-${PRJ}-build
  pushd ${WORKSPACE}/${BB_BDIR_PREFIX}-${PRJ}-build || error "missing ${BB_BDIR_PREFIX}-${PRJ}-build"

  make ${MAKE_PARAMS} || { [ ${IGNORE_ERRORS} = false ] &&  error "Could not make ${PRJ}"; }

  popd
}

# Some projects have weird in-tree build rules.
bb_source_command()
{
  local PRJ="${1}"
  shift
  local CMDS="$@"

  print_stage "Building ${PRJ} with parameters \"${CONFIG_PARAMS}\""
  pushd ${WORKSPACE}/${PRJ} || error "missing ${PRJ}"

  ${CMDS} || error "Could not build ${PRJ}"

  popd
}

regression_email_subject()
{
  local LOGFILE=${1}

  local TARGET=`cat ${LOGFILE} | awk '/Target is/ {print $3; exit}'`

  echo "[BUILDBOT] Regression detected for ${TARGET}"
}

bb_email_regression()
{
  local BUILD_TAG=${1}
  local LOGFILE=${LOGDIR}/${BUILD_TAG}/regression.log

  # Note: Usually you want to install heirloom-mailx, instead of relying
  # on the bsd-mailx default package.

  cat ${LOGFILE} | Mail -s "`regression_email_subject ${LOGFILE}`" ${REGRESSION_RECIPIENTS}
}

bb_email_build_failure()
{
  local BUILD_TAG=${1}
  local LOGFILE=${LOGDIR}/${BUILD_TAG}/build.log

  # Note: Usually you want to install heirloom-mailx, instead of relying
  # on the bsd-mailx default package.

  tail -200 ${LOGFILE} | Mail -s "[BUILDBOT] Build ${BUILD_TAG} failed" ${REGRESSION_RECIPIENTS}
}

# Gather all log files from all build directories
bb_gather_log_files()
{
  local BUILD_TAG=${1}
  local F

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
bb_check_for_regressions()
{
  local PREV_BUILD_TAG=${1}
  local BUILD_TAG=${2}

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
  ( set -x; time bb_daily_target_test ${PREV_BUILD_TAG} ${BUILD_TAG} ) >${LOGDIR}/${BUILD_TAG}/build.log 2>&1
  ST=$?
  [ "${ST}" = "0" ] || bb_email_build_failure ${BUILD_TAG} ${LOGDIR}/${BUILD_TAG}/build.log
  [ "${ST}" = "0" ] && touch ${LOGDIR}/${BUILD_TAG}/pass

  exit ${ST}
}
