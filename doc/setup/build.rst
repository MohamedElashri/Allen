Build Allen
================

There are two options for building Allen: Either as standalone project or as part of the LHCb software stack. The first option is recommended for algorithm developments within Allen, whereas the second is more suitable for integration developments and HLT1 line development and studies.



.. _Allen standalone build:

As standalone project
^^^^^^^^^^^^^^^^^^^^^^^^

Requisites
----------------

The following packages are required in order to be able to compile Allen. Package names listed here are CentOS 7 names, package names for other distributions may slightly change:

* cmake version 3.18 or newer
* boost-devel version 1.69 or newer
* clang version 9 or newer
* json-devel
* zeromq-devel
* zlib-devel
* The Microsoft GSL or alternatively gsl-lite
* python3
* catch2
* umesimd (https://github.com/edanor/umesimd)
* ROOT (https://root.cern/)

The following python3 packages are also needed, which can be installed with pip, conda, or the package manager:

* wrapt
* cachetools
* pydot
* sympy

Further requirements depend on the device chosen as target. Allen supports targets CPU (default), CUDA and HIP. The CUDA target requires a CUDA installation, whereas the HIP target requires a ROCm installation.

Building with CVMFS
-------------------

We show a proposed development setup with the CVMFS filesystem and CentOS 7 that automatically provides all the aforementioned requisites:

First source the LHCb environment::

    source /cvmfs/lhcb.cern.ch/lib/LbEnv

The build process is the standard cmake procedure. You should specify a `CMAKE_TOOLCHAIN_FILE` according to the architecture you want to compile.

* CPU target::

    mkdir build
    cd build
    cmake -DSTANDALONE=ON -DCMAKE_TOOLCHAIN_FILE=/cvmfs/lhcb.cern.ch/lib/lhcb/lcg-toolchains/LCG_101/x86_64-centos7-clang12-opt.cmake ..
    make

* CUDA target::

    mkdir build
    cd build
    cmake -DSTANDALONE=ON -DCMAKE_TOOLCHAIN_FILE=/cvmfs/lhcb.cern.ch/lib/lhcb/lcg-toolchains/LCG_101/x86_64-centos7-clang12+cuda11_4-opt.cmake ..
    make

* HIP target::

    mkdir build
    cd build
    cmake -DSTANDALONE=ON -DCMAKE_TOOLCHAIN_FILE=/cvmfs/lhcb.cern.ch/lib/lhcb/lcg-toolchains/LCG_101/x86_64-centos7-clang12+hip5-opt.cmake ..
    make

In order to run, use the generated wrapper::

    ./toolchain/wrapper ./Allen --sequence hlt1_pp_validation

Building without CVMFS
----------------------

While most requisites can be found as packages on the various OSs, you will need to manually provide the umesimd library::

    git clone https://github.com/edanor/umesimd.git <some_dir>/umesimd
    export UMESIMD_ROOT_DIR=<some_dir>

The build process doesn't differ from standard cmake projects::

    mkdir build
    cd build
    cmake -DSTANDALONE=ON ..
    make

To run Allen, simply invoke the generated binary::

    ./Allen --sequence hlt1_pp_validation

Building on macOS
-----------------

Allen supports macOS, including Apple Silicon, on a best-effort basis. The installation requires the following packages, which can be installed through `brew`::

    brew install llvm cpp-gsl catch2 zeromq nlohmann-json python3 boost
    pip3 install --user wrapt cachetools pydot sympy

It also requires the aforementioned umesimd package::

    git clone https://github.com/edanor/umesimd.git <some_dir>/umesimd
    export UMESIMD_ROOT_DIR=<some_dir>

Due to the recent security features of macOS ignoring `DYLD_LIBRARY_PATH` settings not playing nicely with `cindex.py`'s requirement of `libclang`, it is necessary to provide a symlink in `/usr/local/lib` as follows::

    ln -s /Library/Developer/CommandLineTools/usr/lib/libclang.dylib /usr/local/lib/libclang.dylib

Finally, Allen can be built and run as on any other platform::

    mkdir build
    cd build
    cmake -DSTANDALONE=ON ..
    make
    ./Allen --sequence hlt1_pp_validation

Purging / rebuilding
--------------------

In few cases a `purge` command followed by a rebuild may be required. The cases where this is necessary are described here :ref:`_building_newly_defined_algorithm`.

Compilation options
-------------------

The build process can be configured with cmake options. For a complete list of options and for editing them we suggest using the `ccmake` tool::

    ccmake .

Alternatively, cmake options can be passed with `-D` when invoking the cmake command (eg. `cmake -D<option>=<value> ..`). Here is a brief explanation of some options:

* `STANDALONE` - Selects whether to build Allen standalone or as part of the Gaudi stack. Defaults to `OFF`.
* `TARGET_DEVICE` - Selects the target device architecture. Options are `CPU`, `CUDA` and `HIP`.
* `SEQUENCES` - Either a regex or `all`, if a regex is passed and the pattern is found in a sequence name, it will be built. For a complete list of sequences available, check `configuration/sequences/`. The name of a sequence is given by its filename without the `.py` extension.
* `CMAKE_BUILD_TYPE` - Build type, which is either of `RelWithDebInfo`, `Release` or `Debug`.
* `CUDA_ARCH` - Selects the architecture to target for `CUDA` compilation.
* `HIP_ARCH` - Selects the architecture to target with `HIP` compilation.

Docker
--------
The following lines will build the code base from any computer with NVidia-Docker, assuming you are in the directory with the code checkout and want to build in `build`:

To run allen builder container from a repo container::

  docker-compose up -d

This container would stay attached to this folder as a volume. You will be able to connect and execute commands inside::

  docker-compose exec allen bash
  cmake -GNinja -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang -DCMAKE_CUDA_HOST_COMPILER=clang++ -DCMAKE_CUDA_FLAGS="-allow-unsupported-compiler" -DSTANDALONE=ON -DTARGET_DEVICE=${TARGET} -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DSEQUENCE=${SEQUENCE} -DCPU_ARCH=haswell ..
  ninja
  ./Allen

By default, this docker image would compile the code and run it with the input from the "/input" folder. In the command below we mount `input` inside this repository and mount the build folder, so that it caches built files.

Note: Files inside the build folder would belong to the root user.


As a Gaudi/LHCb project
^^^^^^^^^^^^^^^^^^^^^^^^^^

.. _stack_setup:

Using the stack setup
---------------------
Follow the instructions in the |stack_setup| to set up the software stack.

.. |stack_setup| raw:: html

   <a href="https://gitlab.cern.ch/rmatev/lb-stack-setup" target="_blank">stack setup</a>

To compile an Allen sequence other than the default sequence (hlt1_pp_default), compile for example with::

  make Allen CMAKEFLAGS="-DSEQUENCES=.*"

You can also set the CMAKEFLAGS variable for Allen in `utils/config.json`, the default settings of the stack setup are defined in `utils/default-config.json`.

As a Gaudi/LHCb cmake project
-------------------------------
It then depends on Rec. To build Allen like this, is the same as building
any other Gaudi/LHCb project::

    LbLogin -c x86_64-centos7-gcc9-opt
    cd Allen
    lb-project-init
    make configure
    make install

By default all sequences are built, Allen is built with
CUDA, and the CUDA stack is searched for in `/usr/local/cuda`. These
defaults (and other cmake variables) can be changed by adding the same
flags that you would pass to a standalone build to the `CMAKEFLAGS`
environment variable before calling `make configure`.

For example, to specify another CUDA stack to be used set::

  export CMAKEFLAGS="-DCMAKE_CUDA_COMPILER=/path/to/alternative/nvcc"

Runtime environment:
---------------------
To setup the runtime environment for Allen, the same tools as for
other Gaudi/LHCb projects can be used::

  cd Allen
  ./build.${BINARY_TAG}/run Allen ...


Using the nightlies
---------------------
Create a new directory ``Allen_Gaudi_integration`` and clone both Allen and Moore into this new directory. If a specific version of another repository is needed, that ones needs to be checked out and compiled as well.
Note that this setup uses the nightlies from Tuesday. Adopt the day of the nightly build according to when you are building and check that the nightly build was successful |nightly_builds|::

  lb-set-platform x86_64-centos7-gcc9-opt
  export CMAKE_PREFIX_PATH=/cvmfs/lhcbdev.cern.ch/nightlies/lhcb-head/Tue/:$CMAKE_PREFIX_PATH
  source /cvmfs/projects.cern.ch/intelsw/psxe/linux/all-setup.sh

  ls Allen_Gaudi_integration
  Allen Moore
  export CMAKE_PREFIX_PATH=/path/to/user/directory/Allen_Gaudi_integration:$CMAKE_PREFIX_PATH


.. |nightly_builds| raw:: html

   <a href="https://lhcb-nightlies.web.cern.ch/nightly/" target="_blank">here</a>

Compile both Allen and Moore::

  cd Allen
  lb-project-init
  make configure
  make install

  cd ../Moore
  lb-project-init
  make configure
  make install
