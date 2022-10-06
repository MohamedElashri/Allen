#! /bin/bash

# Author: Mohamed Elashri
# Date:   2022-10-06
# Description: This script is to build Allen on UC sleepy Machine
# Path: build_sleepy.sh


# First check if the OS is centos7 x64 machine only
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" == "centos" ] && [ "$VERSION_ID" == "7" ] && [ "$ID_LIKE" == "rhel fedora" ] && [ "$(uname -m)" == "x86_64" ]; then
        echo "OS is centos 7 x64"
    else
        echo "OS is not centos 7 x64"
        exit 1
    fi
else
    echo "OS is not centos 7 x64"
    exit 1
fi

# Setup the environment
source /cvmfs/lhcb.cern.ch/lib/var/lib/LbEnv/stable/linux-64/bin/activate

# Clone Allen from CERN gitlab
git clone https://gitlab.cern.ch/Allen/Allen.git Allen

# Build Allen
cd Allen
mkdir build
cd build
cmake -DSTANDALONE=ON -DCMAKE_TOOLCHAIN_FILE=/cvmfs/lhcb.cern.ch/lib/lhcb/lcg-toolchains/LCG_101/x86_64-centos7-clang12-opt.cmake ..

# Build the project
make -j 16

# Run a test to see if it works 
toolchain/wrapper ./Allen --sequence=hlt1_pp_default

# If you want to run the test with a different toolchain, you can do
#toolchain/wrapper ./Allen --sequence=hlt1_pp_default --toolchain=/cvmfs/lhcb.cern.ch/lib/lhcb/lcg-toolchains/LCG_101/x86_64-centos7-gcc10-opt.cmake
