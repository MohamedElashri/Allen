###############################################################################
# (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      #
###############################################################################

function setupViews() {
    # setupViews.sh will have unbound variables and lots of output,
    # so disable the x and u flags
    set +x; set +u
    # check LCG_ARCHITECTURE and LCG_VERSION is set
    if [ -z ${LCG_VERSION+x} ]; then
        echo "Error: LCG_VERSION is unset"
        exit 1
    fi

    if [ -z ${LCG_ARCHITECTURE+x} ]; then
        echo "Error: LCG_ARCHITECTURE is unset"
        exit 1
    fi
    if [ -z ${LCG_QUALIFIER+x} ]; then
        echo "Info: LCG_QUALIFIER is unset (CPU build)"
    else
        echo "LCG_QUALIFIER: ${LCG_QUALIFIER}"
        LCG_ARCHITECTURE="${LCG_ARCHITECTURE}+${LCG_QUALIFIER}"
    fi

    if [ -z ${LCG_BUILDTYPE+x} ]; then
        echo "Info: LCG_BUILDTYPE is unset - set to opt"
        LCG_BUILDTYPE="opt"
    fi

    LCG_ARCHITECTURE="${LCG_ARCHITECTURE}-${LCG_BUILDTYPE}"

    
    echo "LCG_VERSION: ${LCG_VERSION}"
    echo "LCG_ARCHITECTURE: ${LCG_ARCHITECTURE}-${LCG_BUILDTYPE}"

    source /cvmfs/lhcb.cern.ch/lib/LbEnv
    export CMAKE_TOOLCHAIN_FILE=/cvmfs/lhcb.cern.ch/lib/lhcb/lcg-toolchains/${LCG_VERSION}/${LCG_ARCHITECTURE}.cmake
    echo "CMAKE_TOOLCHAIN_FILE: ${CMAKE_TOOLCHAIN_FILE}"
    set -u; set -x
}

function source_quietly() {
    set +x; set +u;
    tput -T xterm bold 
    tput -T xterm setaf 2
    echo -e "$ source $1\e[0m"
    source $1
    set -u; set -x
}

function check_build_exists() {
    if [ ! -d ${BUILD_FOLDER} ]; then
        set +x
        echo "======="
        echo "Build folder does not exist at ${BUILD_FOLDER} ..."
        echo " - The build may have failed in the previous stage."
        echo "     ==> Please fix what is causing the build failure, or retry the job."
        echo ""
        echo " - The build matrix is missing a build with these options:"
        echo ""
        echo "     TARGET: ${TARGET}"
        echo "     LCG_ARCHITECTURE: ${LCG_ARCHITECTURE}"
        echo "     BUILD_TYPE: ${BUILD_TYPE}"
        echo "     OPTIONS: ${OPTIONS}"
        echo ""
        echo "   ==> Please add this build and try again (see: scripts/ci/config/common-build.yaml)."
        echo "======="
        exit 1
    fi 
}

# Define OPTIONS as empty, if not already defined
if [ -z ${OPTIONS+x} ]; then
  echo "OPTIONS is not defined - this is fine, but I will set it to empty."
  OPTIONS=""
fi


export BUILD_SEQUENCES="all"

TOPLEVEL=${PWD}
PREVIOUS_IFS=${IFS}
IFS=':' read -ra JOB_NAME_SPLIT <<< "${CI_JOB_NAME}"
IFS=':' read -ra CI_RUNNER_DESCRIPTION_SPLIT <<< "${CI_RUNNER_DESCRIPTION}"
IFS=${PREVIOUS_IFS}

# Extract info about NUMA_NODE or GPU_UUID from CI_RUNNER_DESCRIPTION_SPLIT
if [ "${TARGET}" = "CPU" ]; then
export NUMA_NODE=${CI_RUNNER_DESCRIPTION_SPLIT[2]}
else
export GPU_UUID=${CI_RUNNER_DESCRIPTION_SPLIT[2]}
fi

BUILD_FOLDER="build_${LCG_ARCHITECTURE}_${TARGET}_${BUILD_TYPE}_${BUILD_SEQUENCES}_${OPTIONS}"

ls -la

export PS4=" > "
