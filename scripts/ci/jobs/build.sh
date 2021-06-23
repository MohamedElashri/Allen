#!/usr/bin/bash
###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

# Allow ADDITIONAL_OPTIONS to be unset
if [ -z ${ADDITIONAL_OPTIONS+x} ]; then
  ADDITIONAL_OPTIONS=""
fi

# set -e will force the script to exit if a command quits with a nonzero RC. This avoids silent failures
# set -u forces the script to fail if a variable is unbound / undefined.
# set -x prints all commands to STDERR so you can see what is being executed.
# set -o pipefail causes a nonzero RC to be returned if one of the commands in a pipe fails
set -euxo pipefail

function build_option() {
  export ADDITIONAL_OPTIONS="${ADDITIONAL_OPTIONS} $1"
  echo "Build option added: $1"
}

for opt in $(echo $OPTIONS | sed "s/\+/ /g")
do
  if grep -q "=" <<< "${opt}"; then
    build_option "-D${opt}"
  else
    build_option "-D${opt}=ON"
  fi
done

SOURCE_FOLDER=$(realpath ${PWD})

mkdir -p ${BUILD_FOLDER}
cd ${BUILD_FOLDER}

yum install -y numactl-libs

setupViews

if [ "${TARGET}" = "HIP" ]; then
  source_quietly /cvmfs/lhcbdev.cern.ch/tools/rocm-4.2.0/setenv.sh
  cmake -DSTANDALONE=ON -GNinja -DTARGET_DEVICE=${TARGET} -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DSEQUENCE=${SEQUENCE} -DCPU_ARCH=haswell ${ADDITIONAL_OPTIONS} ${SOURCE_FOLDER}
elif [ "${TARGET}" = "CUDA" ]; then
  source_quietly /cvmfs/sft.cern.ch/lcg/contrib/cuda/11.2/x86_64-centos7/setup.sh
  cmake -DSTANDALONE=ON -GNinja -DTARGET_DEVICE=${TARGET} -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
        -DSEQUENCE=${SEQUENCE} -DCPU_ARCH=haswell ${ADDITIONAL_OPTIONS} \
        -DOVERRIDE_CUDA_ARCH_FLAG="${OVERRIDE_CUDA_ARCH_FLAG}" ${SOURCE_FOLDER}
elif [ "${TARGET}" = "CPU" ]; then
  cmake -DSTANDALONE=ON -GNinja -DTARGET_DEVICE=${TARGET} -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
        -DSEQUENCE=${SEQUENCE} -DCPU_ARCH=haswell ${ADDITIONAL_OPTIONS} \
         ${SOURCE_FOLDER}
else
  echo "Unknown target ${TARGET}. Please check the content of the TARGET variable in the CI configuration."
  exit 1
fi

set +e;
TRIES=0
MAXTRIES=4

while [ $TRIES -le $MAXTRIES ] ; do
  ninja 2>&1 | tee build.log
  RC=$?

  TRIES=$((TRIES + 1))
  # Handle the case where build jobs running concurrently on the
  # runner are not able to share memory, causing OOM failures

  # we decide whether to retry by looking at the output
  if [ $RC -ne 0 ]; then
    RETRY=0

    # g++ fails like this
    if grep -q "fatal error: Killed" build.log ; then
      RETRY=1
    fi

    # clang++ like this
    if grep -q "LLVM ERROR: out of memory" build.log ; then 
      RETRY=1
    fi 

    # if we see this, it's likely we got an OOM from compiling the Stream target
    if grep -q "FAILED: stream" build.log ; then 
      RETRY=1
    fi

    if [ ${RETRY} -ne 0 ]; then
      # retry at least once starting from the target that failed, after waiting between 60 - 90 seconds.
      # choose the wait time randomly, such that if other jobs on the same runner also fail close to this
      # one we are less likely to retry at the same time
      WAIT_TIME=$(python -c "import random; print(${TRIES}*random.randint(60,90))")

      echo "Warning: likely the build failed due to an OOM problem. Will retry from where we left off in $WAIT_TIME seconds."
      sleep $WAIT_TIME;
      continue;
    else
      # something else happened - quit.
      exit $RC
    fi
  fi

  if [ $TRIES -gt 1 ]; then
    # the build was successful, with retries.
    echo "Success - with retries."
    exit 54
  else
    echo "Success."
    exit $RC
  fi
done

echo "Max tries reached."
exit $RC
