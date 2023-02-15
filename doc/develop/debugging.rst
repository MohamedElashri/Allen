.. _debugging:

Debugging
=========

In order to debug you should use a debug build for the target architecture you are interested in. If CVMFS is available, you should use a `dbg` tag such as::

    cmake -DSTANDALONE=ON -DCMAKE_TOOLCHAIN_FILE=/cvmfs/lhcb.cern.ch/lib/lhcb/lcg-toolchains/LCG_101/x86_64-centos7-clang12+cuda11_4-dbg.cmake ..

Then, you should be able to run your code with a debugger such as `gdb` (CPU), `cuda-gdb` (CUDA) or `rocgdb` (HIP). For instance::

    ./toolchain/wrapper /usr/local/cuda/bin/cuda-gdb --args ./Allen --sequence hlt1_pp_validation

If you don't have CVMFS available, you should set the `CMAKE_BUILD_TYPE` to `Debug` and use the available local installation of the debugger::

    cmake -DSTANDALONE=ON -DCMAKE_BUILD_TYPE=Debug -DTARGET_DEVICE=CUDA ..
    cuda-gdb --args ./Allen --sequence hlt1_pp_validation

For some materials on gdb, some recommended reading:

* `gdb tutorial <https://www.cs.cmu.edu/~gilpin/tutorial/>`_
* `cuda-gdb documentation <https://docs.nvidia.com/cuda/cuda-gdb/index.html#getting-started>`_


Use callgrind to create a profile of Allen CPU usage
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
First, make sure to include the correct cmake flags in the build by putting::

    "cmakeFlags": {
        "Allen": "-DCALLGRIND_PROFILE=ON"
    }

in the `utils/config.json` file in your stack before you `make Allen`. Once it is compiled with the flag,  the profile can be created using::

    MooreOnline/build.{tag}/run valgrind --tool=callgrind --instr-atstart=no python Allen/Dumpers/BinaryDumpers/options/allen.py 

with the tags, data, and other flags following as normal. This will create a file in the directory that you ran Allen from named `callgrind.out.xxxxxx` where xxxxxx is a seemingly random 6 digit number. You may need to copy this to another machine where you have installed `qcachegrind` or another program capable of reading callgrind files. On that machine, run::

    qcachegrind callgrind.out.xxxxxx

replacing `callgrind.out.xxxxxx` with your file name. This should launch a window showing the CPU usage of Allen in a variety of different formats including tiles and flowchart.
