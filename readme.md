Allen
=====

[![pipeline status](https://gitlab.cern.ch/lhcb/Allen/badges/master/pipeline.svg)](https://gitlab.cern.ch/lhcb/Allen/-/commits/master)

Welcome to Allen, a project providing a full HLT1 realization on GPU.

Requisites
----------------

The following packages are required in order to be able to compile Allen. Package names listed here are CentOS 7 names, package names for other distributions may slightly change:

* cmake version 3.18 or newer
* boost-devel version 1.69 or newer
* clang version 9 or newer
* json-devel
* zeromq-devel
* zlib-devel
* python3

The following python3 packages are also needed, which can be installed with pip, conda, or the package manager:

* wrapt
* cachetools
* pydot
* sympy

Further requirements depend on the device chosen as target. For each target,
we show a proposed development setup with CVMFS and CentOS 7:

* CPU target: Any modern compiler can be used:

    ```console
    source /cvmfs/sft.cern.ch/lcg/views/setupViews.sh LCG_99 x86_64-centos7-clang10-opt
    ```

* CUDA target: The latest supported compilers are gcc-10 and clang-10. CUDA is
  available in cvmfs as well:

    ```console
    source /cvmfs/sft.cern.ch/lcg/views/setupViews.sh LCG_99 x86_64-centos7-clang10-opt
    source /cvmfs/sft.cern.ch/lcg/contrib/cuda/11.2/x86_64-centos7/setup.sh
    ```

* HIP target: Either a local installation of ROCm or CVMFS are required:

    ```console
    source /cvmfs/sft.cern.ch/lcg/views/setupViews.sh LCG_99 x86_64-centos7-clang10-opt
    source /cvmfs/lhcbdev.cern.ch/tools/rocm-4.2.0/setenv.sh
    ```

Optionally the project can be compiled with ROOT. Histograms of reconstructible and reconstructed tracks are then filled in the track checker. For more details on how to use them to produce plots of efficiencies, momentum resolution etc. see [this readme](checker/plotting/readme.md).

Where to find input
---------------------
For standalone Allen processing, two input file types are supported: MDF and MEP files. MEP files are used during data taking and for integration studies with the online environment. MDF files are the standard input for Allen devlopments. For various samples, MDF files and the corresponding geometry information required for standalone Allen processing have been produced and are available here:

`/eos/lhcb/wg/rta/WP6/Allen/mdf_input/`

The directory name corresponds to the TestFileDB key of the sample. Some of these files have also been copied to the GPU development server (see [this section](#where-to-develop-for-gpus) below), because they are used in the nightly CI tests. These can be found here:

`/scratch/allen_data/mdf_input/`

If other inputs are required, follow these instructions for producing them:
[https://gitlab.cern.ch/lhcb/Allen/blob/master/Dumpers/readme.md](https://gitlab.cern.ch/lhcb/Allen/blob/master/Dumpers/readme.md)

How to build it
---------------

### As standalone project

The build process doesn't differ from standard cmake projects:

    git submodule update --init --recursive
    mkdir build
    cd build
    cmake -DSTANDALONE=ON ..
    make

The build process can be configured with cmake options. For a complete list of options and for editing them we suggest using the `ccmake` tool.

    ccmake .

Alternatively, cmake options can be passed with `-D` when invoking the cmake command (eg. `cmake -D<option>=<value> ..`). Here is a brief explanation of some options:

* `STANDALONE` - Selects whether to build Allen standalone or as part of the Gaudi stack. Defaults to `OFF`.
* `TARGET_DEVICE` - Selects the target device architecture. Options are `CPU` (default), `CUDA` and `HIP` (experimental).
* `SEQUENCE` - Selects the sequence to be compiled (the sequence must be selected at compile time). For a complete list of sequences available, check `configuration/sequences/`. Sequence names should be specified without the `.py` extension, ie. `-DSEQUENCE=velo`.
* `CMAKE_BUILD_TYPE` - Build type, which is either of `RelWithDebInfo` (default), `Release` or `Debug`.
* `USE_ROOT` - Configure to run with / without ROOT. `OFF` by default.
* `CUDA_ARCH` - Selects the architecture to target for `CUDA` compilation.
* `HIP_ARCH` - Selects the architecture to target with `HIP` compilation.

### As a Gaudi/LHCb project

Two ways of calling Allen with Gaudi exist:

1. Use Gaudi to update non-event data such as alignment and configuration constants and use Moore to steer the event loop and call Allen one event at a time (this method will be used for the simulation workflow and efficiency studies)
2. Use Gaudi to update non-event data such as alignment and configuration constants and use Allen to steer the event loop, where batches of events (O(1000)) are processed together (this method will be used for data-taking)

#### Call Allen with Gaudi, steer event loop from Moore
The software can be compiled either based on the nightlies or by compiling the full stack. Both methods are described below.

Instructions on how to call Allen from Moore can be found in [this readme](Rec/Allen/readme.md).


##### Using the stack setup
Follow these [instructions](https://gitlab.cern.ch/rmatev/lb-stack-setup) to set up the software stack. `make Moore` will compile all projects on which it depends as well as Moore itself.
To compile a sequence other than the default sequence (hlt1_pp_default), compile for example with

```
make Allen CMAKEFLAGS='-DSEQUENCE=velo'.
```
Note that default CMAKEFLAGS are set for Allen in `utils/default-config.json` of the stack setup. For convenience, it is easiest to change the sequence there.


##### Using the nightlies

```
lb-set-platform x86_64-centos7-gcc9-opt
export CMAKE_PREFIX_PATH=/cvmfs/lhcbdev.cern.ch/nightlies/lhcb-head/Tue/:$CMAKE_PREFIX_PATH
source /cvmfs/projects.cern.ch/intelsw/psxe/linux/all-setup.sh
```

Create a new directory `Allen_Gaudi_integration` and clone both `Allen` and `Moore` into this new directory.
```
ls Allen_Gaudi_integration
Allen Moore
export CMAKE_PREFIX_PATH=/path/to/user/directory/Allen_Gaudi_integration:$CMAKE_PREFIX_PATH
```

Compile both `Allen` and `Moore`.
```
cd Allen
lb-project-init
make configure
make install

cd ../Moore
lb-project-init
make configure
make install
```

If a specific version of [Rec](https://gitlab.cern.ch/lhcb/Rec) is needed, Rec needs to be compiled as well.
Note that this setup uses the nightlies from Tuesday. Adopt the day of the nightly build according to when you are building. Possibly check that the nightly build was successful.

#### Call Allen with Gaudi, steer event loop from Allen
Allen can also be built as a Gaudi/LHCb cmake project; it then depends
on Rec and Online. To build Allen like this, is the same as building
any other Gaudi/LHCb project:

    LbLogin -c x86_64-centos7-gcc9-opt
    cd Allen
    lb-project-init
    make configure
    make install

##### Build options
By default the `hlt1_pp_default` sequence is selected, Allen is built with
CUDA, and the CUDA stack is searched for in `/usr/local/cuda`. These
defaults (and other cmake variables) can be changed by adding the same
flags that you would pass to a standalone build to the `CMAKEFLAGS`
environment variable before calling `make configure`.

For example, to specify another CUDA stack to be used set:
```console
$> export CMAKEFLAGS="-DCMAKE_CUDA_COMPILER=/path/to/alternative/nvcc"
```

##### Runtime environment:
To setup the runtime environment for Allen, the same tools as for
other Gaudi/LHCb projects can be used:
```console
$> cd Allen
$> ./build.${BINARY_TAG}/run Allen ...
```

##### Run Allen using the Python entry point:
```console
$> cd Allen
$> ./build.${CMTCONFIG}/run bindings/Allen.py
```


How to run the standalone project
-------------

Some binary input files are included with the project for testing.
A run of the program with the help option `-h` will let you know the basic options:

    Usage: ./Allen
    -f, --folder {folder containing data directories}=../input/minbias/
    -g, --geometry {folder containing detector configuration}=../input/detector_configuration/down/
    --mdf {comma-separated list of MDF files to use as input}
    --mep {comma-separated list of MEP files to use as input}
    --transpose-mep {Transpose MEPs instead of decoding from MEP layout directly}=0 (don't transpose)
    --configuration {path to json file containing values of configurable algorithm constants}=Sequence.json
    --print-status {show status of buffer and socket}=0
    --print-config {show current algorithm configuration}=0
    --write-configuration {write current algorithm configuration to file}=0
    -n, --number-of-events {number of events to process}=0 (all)
    -s, --number-of-slices {number of input slices to allocate}=0 (one more than the number of threads)
    --events-per-slice {number of events per slice}=1000
    -t, --threads {number of threads / streams}=1
    -r, --repetitions {number of repetitions per thread / stream}=1
    -m, --memory {memory to reserve per thread / stream (megabytes)}=1024
    -v, --verbosity {verbosity [0-5]}=3 (info)
    -p, --print-memory {print memory usage}=0
    -i, --import-tracks {import forward tracks dumped from Moore}
    --cpu-offload {offload part of the computation to CPU}=1
    --output-file {Write selected event to output file}
    --device {select device to use}=0
    --non-stop {Runs the program indefinitely}=0
    --with-mpi {Read events with MPI}
    --mpi-window-size {Size of MPI sliding window}=4
    --mpi-number-of-slices {Number of MPI network slices}=6
    -h {show this help}

Here are some example run options:

    # Run all input files shipped with Allen once
    ./Allen

    # Specify input files, run once over all of them
    ./Allen -f ../input/minbias/

    # Run a total of 1000 events once without tracking validation. If less than 1000 events are
    # provided, the existing ones will be reused in round-robin.
    ./Allen -n 1000

    # Run four streams, each with 4000 events and 20 repetitions
    ./Allen -t 4 -n 4000 -r 20

    # Run one stream with 5000 events and print all memory allocations
    ./Allen -n 5000 -p 1

    # Default throughput test configuration
    ./Allen -t 16 -n 500 -m 500 -r 1000

Where to develop for GPUs
-------------------------

For development purposes, a server with eight GeForce RTX 2080 Ti GPUs is set up in the online network.
An online account is required to access it. If you need to create one, please send a request to [mailto:lbonsupp@cern.ch](lbonsupp@cern.ch).
Enter the online network from lxplus with `ssh lbgw`. Then `ssh n4050101` to reach the GPU server.

* Upon login, a GPU will be automatically assigned to you.
* Allen input data is available locally under `/scratch/allen_data`.

### How to measure throughput

Every merge request in Allen will automatically be tested in the CI system. As part of the tests, the throughput is measured on a number of different GPUs and a CPU.
The results of the tests are published in this [mattermost channel](https://mattermost.web.cern.ch/lhcb/channels/allenpr-throughput).

For local throughput measurements, we recommend the following settings in Allen standalone mode:

```console
./Allen -f /scratch/allen_data/minbias_mag_down -n 500 -m 500 -r 1000 -t 16
```

Calling Allen with the Nvidia profiler will give information on how much time is spent on which kernel call (note that a slowdown in throughput of around 7% is observed on the master branch when running nvprof, possibly due to the additional data being copied to and from the device):

```console
nvprof ./Allen -f /scratch/allen_data/minbias_mag_down -n 500 -m 500 -r 1000 -t 16
```

### Links to more readmes
The following readmes explain various aspects of Allen:

* [This readme](contributing.md) explains how to add a new algorithm to Allen.
* [This readme](selections.md ) explains how to add a new HLT1 line to Allen.
* [This readme](configuration/readme.md) explains how to configure the algorithms in an HLT1 sequence.
* [This readme](Rec/Allen/readme.md) explains how to call Allen from Moore.
* [Building and running inside Docker](readme_docker.md).
* [Documentation on how to create contracts](doc/contracts.md).

### Mattermost discussion channels

* [Allen developers](https://mattermost.web.cern.ch/lhcb/channels/allen-developers) - Channel for any Allen algorithm development discussion.
* [Allen core](https://mattermost.web.cern.ch/lhcb/channels/allen-core) - Discussion of Allen core features.
* [AllenPR throughput](https://mattermost.web.cern.ch/lhcb/channels/allenpr-throughput) - Throughput reports from nightlies and MRs.
