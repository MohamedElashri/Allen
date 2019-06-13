Allen
=====

Welcome to Allen, a project with the aim to provide a full HLT1 realization on GPU.

Requisites
----------
The project requires a graphics card with CUDA support, CUDA 10.0, CMake 3.12 and a compiler supporting C++17 (gcc 7.3, for instance).

If you are working from a node with CVMFS and CentOS 7, we suggest the following setup:

```shell
source /cvmfs/sft.cern.ch/lcg/views/setupViews.sh LCG_95 x86_64-centos7-gcc7-opt
source /cvmfs/sft.cern.ch/lcg/releases/ROOT/6.16.00-fcdd1/x86_64-centos7-gcc8-opt/bin/thisroot.sh
export PATH=/cvmfs/sft.cern.ch/lcg/contrib/CMake/3.14.2/Linux-x86_64/bin:$PATH
export PATH=/usr/local/cuda/bin:$PATH
```
Regardless of the OS you are running on, you can check your compiler versions as follows:

```shell
$ g++ --version
g++ (GCC) 7.3.0

$ nvcc --version
Cuda compilation tools, release 10.0, V10.0.130

$ cmake --version
cmake version 3.14.2
```

You can check your compiler standard compatibility by scrolling to the `C++17 features` chart [here](https://en.cppreference.com/w/cpp/compiler_support).

Optionally you can compile the project with ROOT. Then, trees will be filled with variables to check when running the UT tracking or SciFi tracking algorithms on x86 architecture.
In addition, histograms of reconstructible and reconstructed tracks are then filled in the track checker. For more details on how to use them to produce plots of efficiencies, momentum resolution etc. see [this readme](checker/tracking/readme.md).

[Building and running inside Docker](readme_docker.md)

Where to find input
-------------
Input from 1k events (mag down) can be found here:

* minimum bias (for performance checks): `/afs/cern.ch/work/d/dovombru/public/gpu_input/1kevents_minbias_dump_region_UT_fix.tar.gz`
* Bs->PhiPhi (for efficiency checks): `/afs/cern.ch/work/d/dovombru/public/gpu_input/1kevents_BsPhiPhi_dump_region_UT_fix.tar.gz`
* J/Psi->MuMu (for muon efficiency checks): `/afs/cern.ch/work/d/dovombru/public/gpu_input/1kevents_JPsiMuMu_dump_region_UT_fix.tar.gz`

5k Bs2PhiPhi events (mag down) are avialable here: `/afs/cern.ch/work/d/dovombru/public/gpu_input/BsPhiPhi/BsPhiPhi.tar.gz`

30k minbias events (mad down) are available here: `/afs/cern.ch/work/d/dovombru/public/gpu_input/minbias.tar.gz`

Another 5k Bs2PhiPhi events for both magnet polarities are available. The directory contains sub-directories `mag_up` and `mag_down` and the events are compressed in a tar file separately for the two polarities.
 `/eos/lhcb/wg/rta/WP6/Allen/binary_input/Bs2PhiPhi`

Input for various different physics channels for HLT1 studies in both magnet polarities is available. The directory structure is the same as for the Bs2PhiPhi events. 
They can be found here:
* Z2MuMu: `/eos/lhcb/wg/rta/WP6/Allen/binary_input/Z2MuMu`
* Ds2KKPi: `/eos/lhcb/wg/rta/WP6/Allen/binary_input/Ds2KKPi`
* KstEE: `/eos/lhcb/wg/rta/WP6/Allen/binary_input/KstEE`
* KstMuMu: `/eos/lhcb/wg/rta/WP6/Allen/binary_input/KstMuMu`

How to build it
---------------

The build process doesn't differ from standard cmake projects:

    mkdir build
    cd build
    cmake ..
    make

There are some cmake options to configure the build process:

* The sequence can be configured by specifying `-DSEQUENCE=<name_of_sequence>`. For a complete list of sequences available, check `configuration/sequences/`. Sequence names should be specified without the `.h`, ie. `-DSEQUENCE=VeloPVUTSciFiDecoding`.
* The build type can be specified to `RelWithDebInfo`, `Release` or `Debug`, e.g. `cmake -DCMAKE_BUILD_TYPE=Debug ..`
* ROOT can be enabled to generate monitoring plots using `-DUSE_ROOT=ON`
* If more verbose build output from the CUDA toolchain is desired, specify `-DCUDA_VERBOSE_BUILD=ON`
* If multiple versions of CUDA are installed and CUDA 10.0 is not the default, it can be specified using: `-DCMAKE_CUDA_COMPILER=/usr/local/cuda-10.0/bin/nvcc`
* The MC validation is standalone, it was written by Manuel Schiller, Rainer Schwemmer, Daniel Cámpora and Dorothea vom Bruch.

How to run it
-------------

Some binary input files are included with the project for testing.
A run of the program with no arguments will let you know the basic options:

    Usage: ./Allen
    -f {folder containing directories with raw bank binaries for every sub-detector}
    -b {folder containing .bin files with muon common hits}
    --mdf {use MDF files as input instead of binary files}
    -g {folder containing detector configuration}
    -d {folder containing .bin files with MC truth information}
    -n {number of events to process}=0 (all)
    -o {offset of events from which to start}=0 (beginning)
    -t {number of threads / streams}=1
    -r {number of repetitions per thread / stream}=1
    -c {run checkers}=0
    -m {reserve Megabytes}=1024
    -v {verbosity}=3 (info)
    -p {print memory usage}=0
    -a {run only data preparation algorithms: decoding, clustering, sorting}=0

Here are some example run options:

    # Run all input files once with the tracking validation
    ./Allen

    # Specify input files, run once over all of them with tracking validation
    ./Allen -f ../input/minbias/

    # Run a total of 1000 events, round robin over the existing ones, without tracking validation
    ./Allen -c 0 -n 1000

    # Run four streams, each with 4000 events, 20 repetitions
    ./Allen -t 4 -n 4000 -r 20 -c 0

    # Run one stream and print all memory allocations
    ./Allen -n 5000 -p

How to run build and run together with the LHCb stack
-----------------------------------------------------

Code is being developed in the LHCb stack that provides detector
geometry data directly instead of reading it from binary files. To do
this, the following is required:
 - Build with CUDA 10.1 (to allow gcc 8 as a host compiler)
 - Build the Rec project against the lhcb-gaudi-head nightly build
 - Build Allen using the same toolchain as Rec
 - Run Allen from a runtime environment provided by Rec

### Building Rec
Running Allen together with the LHCb stack requires some recent
changes that have not yet been merged to master. Rec has to be built
in its entirity against the lhcb-gaudi-head slot. First, decide on a
directory where it will reside (`dev-dir` below) and then clone there:
 - `mkdir /path/to/dev-dir`
 - `cd /path/to/dev-dir`

To setup the LHCb environment for building and running Rec, put the
following in a script (e.g. `env.sh`) for easy access:
```console
export CMTCONFIG=x86_64-centos7-gcc8-opt
export CMTPROJECTPATH=/path/to/dev-dir:/cvmfs/lhcbdev.cern.ch/nightlies/lhcb-gaudi-head/Mon
source /cvmfs/lhcb.cern.ch/lib/LbEnv
```

Then build Rec:
 - `source env.sh`
 - `git clone ssh://git@gitlab.cern.ch:7999/lhcb/Rec.git`
 - `cd Rec`
 - `lb-project-init`
 -`'git checkout -b allen_producers origin/raaij_allen_producers`
 - `make install`

### Building Allen with the toolchain used for Rec
In the same environment, do the following
 - `cd /path/to/Allen`
 - `mkdir build-Rec`
 - `cd build-Rec`
 - `/path/to/dev-dir/Rec/build.${CMTCONFIG}/run bash --norc`
 - ```cmake -DCMAKE_C_COMPILER=`which gcc` -DCMAKE_CXX_COMPILER=`which g++` -DCMAKE_CUDA_COMPILER=/usr/local/cuda-10.1/bin/nvcc ..```
 - `make -j 10`

### Run Allen using the Python entry point:
```console
$> /path/to/dev-dir/Rec/build.${CMTCONFIG}/run /path/to/Allen/bindings/Allen.py
```


[This readme](contributing.md) explains how to add a new algorithm to the sequence and how to use the memory scheduler to define global memory variables for this sequence and pass on the dependencies. It also explains which checks to do before placing a merge request with your changes.
