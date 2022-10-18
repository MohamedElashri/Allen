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
