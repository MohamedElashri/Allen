Allen
=====

Welcome to Allen, a project providing a full HLT1 realization on GPU.

Requisites
----------
The project requires a graphics card with CUDA support, CUDA 10.0, CMake 3.12 and a compiler supporting C++17.

If you are working from a node with CVMFS and CentOS 7, we suggest the following setup:

```shell
source /cvmfs/sft.cern.ch/lcg/views/setupViews.sh LCG_95 x86_64-centos7-gcc8-opt
export PATH=/cvmfs/sft.cern.ch/lcg/contrib/CMake/3.14.2/Linux-x86_64/bin:$PATH
export PATH=/usr/local/cuda/bin:$PATH
```
Regardless of the OS you are running on, you can check your compiler versions as follows:

```shell
$ g++ --version
g++ (GCC) 8.2.0

$ nvcc --version
Cuda compilation tools, release 10.1, V10.1.243

$ cmake --version
cmake version 3.14.2
```

You can check your compiler standard compatibility by scrolling to the `C++17 features` chart [here](https://en.cppreference.com/w/cpp/compiler_support).

Optionally you can compile the project with ROOT. Then, trees will be filled with variables to check when running the UT tracking or SciFi tracking algorithms on x86 architecture.
In addition, histograms of reconstructible and reconstructed tracks are then filled in the track checker. For more details on how to use them to produce plots of efficiencies, momentum resolution etc. see [this readme](checker/tracking/readme.md).

[Building and running inside Docker](readme_docker.md)

Where to find input
-------------
Input from 5k events for each of the following decay modes can be found here:

* minimum bias, mag down: `/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/minbias/minbias_mag_down.tar.gz`
* Bs->PhiPhi, mag down: `/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/Bs2PhiPhi/mag_down.tar.gz`
* Bs->PhiPhi, mag up: `/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/Bs2PhiPhi/mag_up.tar.gz`
* J/Psi->MuMu, mag down: `/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/JpsiMuMu/mag_down.tar.gz`
* Ds->KKPi, mag down: `/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/Ds2KKPi/Ds2KKPi_mag_down.tar.gz`
* B->KstEE, mag down: `/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/KstEE/KstEE_mag_down.tar.gz`
* B->KstMuMu, mag down: `/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/KstMuMu/KstMuMu_mag_down.tar.gz`
* Z->MuMu, mag down: `/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/Z2MuMu/Z2MuMu_mag_down.tar.gz`
* Ks0->MuMu, mag down: `/eos/lhcb/wg/rta/WP6/Allen/binary_input_2019-07/Ks0mumu/Ks02MuMu_mag_down.tar.gz`

If other inputs are required, follow these instructions for producing them:
[https://gitlab.cern.ch/lhcb/Allen/blob/allen_tdr/Dumpers/readme.md](https://gitlab.cern.ch/lhcb/Allen/blob/allen_tdr/Dumpers/readme.md)

Allen selections require ODIN banks, which were not included with these samples. Random ODIN banks can be generated using `makeODIN.py`. From the Allen root directory:

```shell
python3 scripts/makeODIN.py /path/to/data/banks/
```

This will create a random ODIN bank for each bank in `/path/to/data/banks/VP`.

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

How to enable Nvidia persistenced mode
-----------------------------------------
Enabling Nvidia [persistenced mode](https://docs.nvidia.com/deploy/driver-persistence/index.html) will increase the throughput of Allen, as the GPU will remain initialized even when no process is running. To enable:
`sudo systemctl enable nvidia-persistenced`, reboot the machine.

How to profile it
------------------
For profiling, Nvidia's nvprof can be used.
Since CUDA version 10.1, profiling was limited to the root user by default for security reasons. However, the system administrator of a GPU server can add a kernel module option such that regular users can use the profiler by following these instructions:

Add a file containing "option nvidia NVreg_RestrictProfilingToAdminUsers=0" to the `/etc/modprobe.d/` directory and reboot the machine. This will load the nvidia kernel module with "NVreg_RestrictProfilingToAdminUsers=0".

As a quick workaround one can also use the older version of nvprof:

    /usr/local/cuda-10.0/bin/nvprof ./Allen -c 0 -n 1000

Building as a Gaudi/LHCb project
--------------------------------

Allen can also be built as a Gaudi/LHCb cmake project; it then depends
on Rec and Online. To build Allen like this, is the same as building
any other Gaudi/LHCb project:

    LbLogin -c x86_64-centos7-gcc9-opt
    cd Allen
    lb-project-init
    make configure
    make install

### Build options
By default the `DefaultSequence` is selected, Allen is built with
CUDA, and the CUDA stack is searched for in `/usr/local/cuda`. These
defaults (and other cmake variables) can be changed by adding the same
flags that you would pass to a standalone build to the `CMAKEFLAGS`
environment variable before calling `make configure`.

For example, to specify another CUDA stack to be used set:
```console
$> export CMAKEFLAGS="-DCMAKE_CUDA_COMPILER=/path/to/alternative/nvcc"
```

### Runtime environment:
To setup the runtime environment for Allen, the same tools as for
other Gaudi/LHCb projects can be used:
```console
$> cd Allen
$> ./build.${BINARY_TAG}/run Allen ...
```

### Run Allen using the Python entry point:
```console
$> cd Allen
$> ./build.${CMTCONFIG}/run bindings/Allen.py
```

[This readme](contributing.md) explains how to add a new algorithm to the sequence and how to use the memory scheduler to define global memory variables for this sequence and pass on the dependencies. It also explains which checks to do before placing a merge request with your changes.
