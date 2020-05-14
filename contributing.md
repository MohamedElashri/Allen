Allen: Adding a new CUDA algorithm
=====================================

This tutorial will guide you through adding a new CUDA algorithm to the `Allen` project.

SAXPY
-----

Writing an algorithm in CUDA in the `Allen` project is no different than writing it on any other GPU project. The differences are in how to invoke that program, and how to setup the options, arguments, and so on.

So let's assume that we have the following simple `SAXPY` algorithm, taken out from this website https://devblogs.nvidia.com/easy-introduction-cuda-c-and-c/

```clike=
__global__ void saxpy(float *x, float *y, int n, float a) {
  int i = blockIdx.x*blockDim.x + threadIdx.x;
  if (i < n) y[i] = a*x[i] + y[i];
}
```

### Adding the CUDA algorithm

We want to add the algorithm to a specific folder inside the `cuda` folder:

```
├── cuda
│   ├── CMakeLists.txt
│   └── velo
│       ├── CMakeLists.txt
│       ├── calculate_phi_and_sort
│       │   ├── include
│       │   │   └── CalculatePhiAndSort.cuh
│       │   └── src
│       │       ├── CalculatePhiAndSort.cu
│       │       ├── CalculatePhi.cu
│       │       └── SortByPhi.cu
│       ├── common
│       │   ├── include
│       │   │   ├── ClusteringDefinitions.cuh
│       │   │   └── VeloDefinitions.cuh
│       │   └── src
│       │       ├── ClusteringDefinitions.cu
│       │       └── Definitions.cu
...
```

Let's create a new folder inside the `cuda` directory named `example`. We need to modify `cuda/CMakeLists.txt` to reflect this:

```cmake=
add_subdirectory(raw_banks)
add_subdirectory(example)
```

Inside the `test` folder we will create the following structure:

```
├── test
│   ├── CMakeLists.txt
│   └── example
│       ├── include
│       │   └── Saxpy_example.cuh
│       └── src
│           └── Saxpy_example.cu
```

The newly created `test/CMakeLists.txt` file should reflect the project we are creating. We can do that by populating it like so:

```cmake=
file(GLOB saxpy_sources "src/*cu")

include_directories(include)
include_directories(../velo/common/include)
include_directories(../event_model/common/include)
include_directories(../event_model/velo/include)

include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)

if(TARGET_DEVICE STREQUAL "CPU" OR TARGET_DEVICE STREQUAL "CUDACLANG")
  foreach(source_file ${saxpy_sources})
    set_source_files_properties(${source_file} PROPERTIES LANGUAGE CXX)
  endforeach(source_file)
endif()

allen_add_device_library(Saxpy STATIC
  ${saxpy_sources}
)
```
The includes of Velo and event model files are only necessary because we will use the number of Velo tracks per event as an input to the saxpy algorithm.
If your new algorithm does not use any Velo related objects, this is not necessary.

The includes of main, gear and sequence are required for any new algorithm in Allen.

Link the new library "Saxpy" to the stream librariy in `stream/CMakeLists.txt`:
```cmake=
target_link_libraries(Stream PRIVATE
  HostStream
  CudaCommon
  Associate
  Velo
  AllenPatPV
  PV_beamline
  HostClustering
  HostPrefixSum
  UT
  Kalman
  VertexFitter
  RawBanks
  SciFi
  HostGEC
  Muon
  Utils
  Saxpy)
```

Next, we create the header file for our algorithm `SAXPY_example.cuh`, which is similar to an algorithm definition in Gaudi: inputs, outputs and properties are defined, as well as the algorithm function itself and an operator calling the function.
There are slight differences to Gaudi, since we want to be able to run the algorithm on a GPU.
The full file can be viewed [here](https://gitlab.cern.ch/lhcb/Allen/blob/dovombru_update_documentation/cuda/example/include/SAXPY_example.cuh). Let's take a look at the components:

```clike=
#pragma once

#include "VeloConsolidated.cuh"
#include "DeviceAlgorithm.cuh"
```
The Velo include is only required if Velo objects are used in the algorithm. `DeviceAlgorithm.cuh` needs to be included for every device algorithm.

```clike=
namespace saxpy {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);

    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint) dev_atomics_velo; 
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
        
    DEVICE_OUTPUT(dev_saxpy_output_t, float) dev_saxpy_output;

    PROPERTY(saxpy_scale_factor_t, "saxpy_scale_factor", "scale factor a used in a*x + y", float) saxpy_scale_factor;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions);
  };
```


In the `saxpy` namespace the inputs and outputs are specified. These can refer to data either on the host or on the device. So one can choose between `HOST_INPUT`, `HOST_OUTPUT`, `DEVICE_INPUT` and `DEVICE_OUTPUT`.
In all cases the name and type are defined, e.g. ` DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint)`. An algorithm can be called several times in a sequence with different inputs, outputs and properties.
The default input name to be used can be set by ` DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint) dev_atomics_velo;`. A `PROPERTY` describes a constant used in an algorithm, the default value of a property is set when declaring it, as described below.


```clike=
__global__ void saxpy(Parameters);

```
The function of the algorithm is defined. 

```clike=
  template<typename T, char... S>
  struct saxpy_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(saxpy)) function {saxpy};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_saxpy_output_t>(
                                   arguments, value<host_number_of_selected_events_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      function(dim3(value<host_number_of_selected_events_t>(arguments) / property<block_dim_t>()), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_saxpy_output_t>(arguments),
            property<saxpy_scale_factor_t>()});
    }

    private:
        Property<saxpy_scale_factor_t> m_saxpy_factor {this, 2.f};
        Property<block_dim_t> m_block_dim {this, {32, 1, 1}};
  };
} // namespace saxpy
```
In ` struct saxpy_t`, the function call is handled. Note that the name of the struct must match the function name (`saxpy`), followed by `_t`.
In `set_arguments_size`, the sizes of `DEVICE_OUTPUT` parameters are defined. The actual memory allocation is handled by the memory manager. In our case, for `dev_saxpy_output_t` we reserve `<host_number_of_selected_events_t * sizeof(float)` bytes of memory.
The `sizeof(float)` is implicit, because we set the type of `dev_saxpy_output_t` to float in the `Parameters` struct.
In the call to `function` the first two arguments are the number of blocks per grid (`dim3(value<host_number_of_selected_events_t>(arguments) / property<block_dim_t>())`) and the number
of threads per block (`property<block_dim_t>()`). The struct `Parameters` contains the pointers to all `DEVICE_INPUT` and `DEVICE_OUTPUT` which were defined in the `Parameters` struct above, as well as the `PROPERTY`s.
Finally, the properties belonging to the algorithm are defined as private members of the `saxpy_t` struct together with their default values.

If a new variable is required in host memory, allocate its memory like so:
Go to `stream/sequence/include/HostBuffers.cuh` and add the new host memory pointer:

```clike
  // Pinned host datatypes
  uint* host_velo_tracks_atomics;
  uint* host_velo_track_hit_number;
```

Reserve that host memory in `stream/sequence/src/HostBuffers.cu`:

```clike
  cudaCheck(cudaMallocHost((void**)&host_velo_tracks_atomics, (2 * max_number_of_events + 1) * sizeof(int)));
  cudaCheck(cudaMallocHost((void**)&host_velo_track_hit_number, max_number_of_events * VeloTracking::max_tracks * sizeof(uint)));
 
```


Next, we add the [source file](https://gitlab.cern.ch/lhcb/Allen/blob/dovombru_update_documentation/cuda/example/src/SAXPY_example.cu):

```clike
#include "SAXPY_example.cuh"

__global__ void saxpy::saxpy(
  saxpy::Parameters parameters)
  {
    const uint number_of_events = gridDim.x;
    const uint event_number = blockIdx.x * blockDim.x + threadIdx.x;

    Velo::Consolidated::ConstTracks velo_tracks {
      parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_evnts};
    const uint number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
    
    if (event_number < number_of_events)
      parameters.dev_saxpy_output[event_number] = parameters.saxpy_scale_factor * number_of_tracks_event + number_of_tracks_event;
}
```
The source code looks like any other CUDA function, with the only difference being that Allen inputs and outputs, as well as properties are passed via the `saxpy::Parameters` struct. 
The are accessed as in `parameters.dev_atomics_velo` (DEVICE_INPUT) or `parametres.saxpy_scale_factor` (PROPERTY).

To integrate the new algorithm into a sequence, please follow [this]() readme.
