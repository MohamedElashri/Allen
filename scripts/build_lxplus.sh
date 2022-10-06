#! /bin/bash

# Author: Mohamed Elashri
# Date:   2022-10-06
# Description: This script is to build Allen on CERN lxplus
# Path: build_lxplus.sh


# Setup the environment
source /cvmfs/lhcb.cern.ch/lib/LbEnv

# Clone Allen from CERN gitlab
git clone https://gitlab.cern.ch/Allen/Allen.git Allen

# Build Allen
cd Allen
mkdir build
cd build
cmake -DSTANDALONE=ON -DCMAKE_TOOLCHAIN_FILE=/cvmfs/lhcb.cern.ch/lib/lhcb/lcg-toolchains/LCG_101/x86_64-centos7-clang12-opt.cmake ..

# Build the project
make -j 4

# Run a test to see if it works 
toolchain/wrapper ./Allen --sequence=hlt1_pp_default

# If you want to run the test with a different toolchain, you can do
#toolchain/wrapper ./Allen --sequence=hlt1_pp_default --toolchain=/cvmfs/lhcb.cern.ch/lib/lhcb/lcg-toolchains/LCG_101/x86_64-centos7-gcc10-opt.cmake

