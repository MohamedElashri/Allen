Build Allen with HIP
====================

HIP stands for Heterogeneous compute Interface for Portability. It is
mainly supported on AMD GPGPUs. In addition to the requirements
defined in [readme.md](readme.md#Requisites), a graphics card with AMD
ROCm support is required to run Allen with HIP.

Please note that Allen built with HIP is currently for development
purposes, the binary does not (yet) run.

on CentOS 7, the following exports are required to configure HIP:
```shell
$> export HIP_PLATFORM=hcc
$> export HCC_AMDGPU_TARGET=<GPU Plateform for Vega7 for eg. "gfx906">

```

To check the version of HIP, use:
```shell
$> hipcc --version
HIP version: 1.5.19211
```

To check if HIP is configured properly, use:
```shell
$> hipconfig
```

To compile with HIP, add `-DHIP=ON` when configuring Allen, as below:
```
$> mkdir build-hip
$> cd build-hip
$> cmake -DHIP=ON ..
$> make
```

There is a working branch based on v5 which compiles and runs on AMD GPGPUs [here](https://gitlab.cern.ch/lhcb-parallelization/Allen/tree/Brij-Carlos-Allen-HIP-v5-working)
