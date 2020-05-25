Allen: Adding a new device algorithm
====================================

This tutorial will guide you through adding a new device algorithm to the `Allen` framework.

SAXPY
-----

Writing functions to be executed in the device in `Allen` is literally the same as writing a CUDA kernel. Therefore, you may use any existing tutorial or documentation on how to write good CUDA code.

Writing a device algorithm in the `Allen` framework has been made to resemble the Gaudi syntax, where possible.

Let's assume that we want to run the following classic `SAXPY` CUDA kernel, taken out from this website https://devblogs.nvidia.com/easy-introduction-cuda-c-and-c/ :

```c++
__global__ void saxpy(float *x, float *y, int n, float a) {
  int i = blockIdx.x*blockDim.x + threadIdx.x;
  if (i < n) y[i] = a*x[i] + y[i];
}
```

### Adding the device algorithm

We want to add the algorithm to a specific folder inside the `device` folder:

```console
device
├── associate
│   ├── CMakeLists.txt
│   ├── include
│   │   ├── AssociateConstants.cuh
│   │   └── VeloPVIP.cuh
│   └── src
│       └── VeloPVIP.cu
├── CMakeLists.txt
├── event_model
│   ├── associate
│   │   └── include
│   │       └── AssociateConsolidated.cuh
│   ├── common
│   │   └── include
│   │       ├── ConsolidatedTypes.cuh
│   │       └── States.cuh
...
```

Let's create a new folder inside the `device` directory named `example`. We need to modify `device/CMakeLists.txt` to reflect this:

```cmake
add_subdirectory(raw_banks)
add_subdirectory(example)
```

Inside the `test` folder we will create the following structure:

```console
├── test
│   ├── CMakeLists.txt
│   └── example
│       ├── include
│       │   └── Saxpy_example.cuh
│       └── src
│           └── Saxpy_example.cu
```

The newly created `test/CMakeLists.txt` file should reflect the project we are creating. We can do that by populating it like so:

```cmake
file(GLOB saxpy_sources "src/*cu")

include_directories(include)
include_directories(${CMAKE_SOURCE_DIR}/device/velo/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/common/include)
include_directories(${CMAKE_SOURCE_DIR}/device/event_model/velo/include)
include_directories(${CMAKE_SOURCE_DIR}/main/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/gear/include)
include_directories(${CMAKE_SOURCE_DIR}/stream/sequence/include)

allen_add_device_library(Examples STATIC
  ${saxpy_sources}
)
```
The includes of Velo and event model files are only necessary because we will use the number of Velo tracks per event as an input to the saxpy algorithm.
If your new algorithm does not use any Velo related objects, this is not necessary.

The includes of main, gear and sequence are required for any new algorithm in Allen.

Link the new library "Examples" to the stream library in `stream/CMakeLists.txt`:
```cmake
target_link_libraries(Stream PRIVATE
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
  Selections
  SciFi
  HostGEC
  Muon
  Utils
  Examples
  HostDataProvider
  HostInitEventList)
```

Next, we create the header file for our algorithm `SAXPY_example.cuh`, which is similar to an algorithm definition in Gaudi: inputs, outputs and properties are defined, as well as the algorithm function itself and an operator calling the function.

There are slight differences to Gaudi, since we want to be able to run the algorithm on a GPU.
The full file is under `device/example/include/SAXPY_example.cuh`. Let's take a look at the components:

```c++
#pragma once

#include "VeloConsolidated.cuh"
#include "DeviceAlgorithm.cuh"
```

The Velo include is only required if Velo objects are used in the algorithm. `DeviceAlgorithm.cuh` defines class `DeviceAlgorithm` and some other handy resources.

#### Parameters and properties

```c++
namespace saxpy {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events),
    (DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned), dev_atomics_velo),
    (DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned), dev_velo_track_hit_number),
    (DEVICE_OUTPUT(dev_saxpy_output_t, float), dev_saxpy_output),
    (PROPERTY(saxpy_scale_factor_t, "saxpy_scale_factor", "scale factor a used in a*x + y", float), saxpy_scale_factor),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))
```

In the `saxpy` namespace the parameters and properties are specified. Parameters _scope_ can either be the host or the device, and they can either be inputs or outputs. Parameters should be defined with the following convention:

    (<scope>_<io>(<name>, <type>), <identifier>)

Some parameter examples:

* `(DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned), dev_atomics_velo)`: Defines an input on the _device memory_. It has a name `dev_offsets_all_velo_tracks_t`, which can be later used to identify this argument. It is of type _unsigned_, which means the memory location named `dev_offsets_all_velo_tracks_t` holds `unsigned`s. The _io_ and the _type_ define the underlying type of the instance to be `<io> <type> *` -- in this case, since it is an input type, `const unsigned*`. Its identifier is `dev_atomics_velo`.
* `(DEVICE_OUTPUT(dev_saxpy_output_t, float), dev_saxpy_output)`: Defines an output parameter on _device memory_, with name `dev_saxpy_output_t` and identifier `dev_saxpy_output`. Its underlying type is `float*`.
* `(HOST_INPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events)`: Defines an input parameter on _host memory_, with name `host_number_of_selected_events_t` and identifier `host_number_of_selected_events`. Its underlying type is `const unsigned*`.

Properties of algorithms define constants can be configured prior to running the application. They are defined in two parts. First, they should be defined in the `DEFINE_PARAMETERS` macro following the convention:

    (PROPERTY(<name>, <key>, <description>, <type>), <identifier>)

* `(PROPERTY(saxpy_scale_factor_t, "saxpy_scale_factor", "scale factor a used in a*x + y", float), saxpy_scale_factor)`: Property with name `saxpy_scale_factor_t` is of type `float`. It will be accessible through key `"saxpy_scale_factor"` in a python configuration file, and it has description `"scale factor a used in a*x + y"`. Its identifier is `saxpy_scale_factor`. Properties _underlying type_ is always the same as their type, so in this case `float`.

And second, properties should be defined inside the algorithm struct as follows:

    Property<_name_> _internal_name_ {this, _default_value_}

In the case of saxpy:

```c++
  private:
    Property<saxpy_scale_factor_t> m_saxpy_factor {this, 2.f};
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
```

#### Defining an algorithm

##### SAXPY_example.cuh

An algorithm is defined by a `struct` (or `class`) that inherits from either `HostAlgorithm` or `DeviceAlgorithm`. In addition, it is convenient to also inherit from `Parameters`, to be able to easily access _identifiers_ of parameters and properties. The struct identifier is the name of the algorithm.

An algorithm must define **two methods**: `set_arguments_size` and `operator()`. Their signatures are as follows:

```c++
  struct saxpy_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters>,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t&,
      cudaEvent_t&) const;

  private:
    Property<saxpy_scale_factor_t> m_saxpy_factor {this, 2.f};
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
  };
```

An algorithm `saxpy_t` has been declared. It is a `DeviceAlgorithm`, and for convenience it inherits from the previously defined `Parameters`. It defines two methods, `set_arguments_size` and `operator()` with the above predefined signatures. The algorithm declaration ends with the `private:` block for the properties mentioned before.

Since this is a DeviceAlgorithm, one would like the work to actually be done on the device. In order to run code on the device, a _global kernel_ has to be defined. The syntax used is standard CUDA:

```
__global__ void saxpy(Parameters, const unsigned number_of_events);
```

##### SAXPY_example.cu

The source file of SAXPY should define `set_arguments_size`, `operator()` and the previously mentioned _global kernel_ `saxpy`:

* `set_arguments_size`: Sets the `size` of output parameters.
* `operator()`: The actual algorithm runs (similar to Gaudi).

In Allen, it is not recommended to use _dynamic memory allocations_. Therefore, types such as `std::vector` are "forbidden", and instead sizes of output arguments must be set in the `set_arguments_size` method of algorithms.

```c++
#include "SAXPY_example.cuh"

void saxpy::saxpy_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_saxpy_output_t>(arguments, first<host_number_of_selected_events_t>(arguments));
}
```

To do that, one may use the following functions:

* `void set_size<T>(arguments, const size_t)`: Sets the size of _name_ `T`. The `sizeof(T)` is implicit, so eg. `set_size<T>(10)` will actually allocate space for `10 * sizeof(T)`.
* `size_t size<T>(arguments)`: Gets the size of _name_ `T`.
* `T* data<T>(arguments)`: Gets the pointer to the beginning of `T`.
* `T first<T>(arguments)`: Gets the first element of `T`.

Next, `operator()` should be defined:

```c++
void saxpy::saxpy_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers&,
  cudaStream_t& cuda_stream,
  cudaEvent_t&) const
{
  global_function(saxpy)(
    dim3(1),
    property<block_dim_t>(),
    cuda_stream)(arguments, first<host_number_of_selected_events_t>(arguments));
}
```

In order to invoke host and global functions, wrapper methods `host_function` and `global_function` should be used. The syntax is as follows:

    host_function(<host_function_identifier>)(<parameters of function>)
    global_function(<global_function_identifier>)(<grid_size>, <block_size>, <stream>)(<parameters of function>)

`global_function` wraps a function identifier, such as `saxpy`. The object it returns can be used to invoke a _global kernel_ following a syntax that is similar to [CUDA's kernel invocation syntax](https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#kernels). It expects:

* `grid_size`: Number of blocks of kernel invocation (passed as 3-dimensional object of type `dim3`).
* `block_size`: Number of threads in each block (passed as 3-dimensional object of type `dim3`).
* `stream`: Stream where to run.
* `parameters of function`: Parameters of the _global kernel_ being invoked.

In this case, the kernel `saxpy` accepts only one parameter of type `Parameters`. The global_function and host_function wrappers automatically detect and transform `const ArgumentReferences<Parameters>&` into `Parameters`. Therefore, we can safely pass `arguments` to our kernel invocation.

Finally, the kernel is defined:

```c++
/**
 * @brief SAXPY example algorithm
 * @detail Calculates for every event y = a*x + x, where x is the number of velo tracks in one event
 */
__global__ void saxpy::saxpy(saxpy::Parameters parameters, const unsigned number_of_events)
{
  for (unsigned event_number = threadIdx.x; event_number < number_of_events; event_number += blockDim.x) {
    Velo::Consolidated::ConstTracks velo_tracks {
      parameters.dev_atomics_velo, parameters.dev_velo_track_hit_number, event_number, number_of_events};
    const unsigned number_of_tracks_event = velo_tracks.number_of_tracks(event_number);
    
    parameters.dev_saxpy_output[event_number] =
        parameters.saxpy_scale_factor * number_of_tracks_event + number_of_tracks_event;
  }
}
```

The kernel accepts a single parameter of type `saxpy::Parameters`. It is now possible to access all previously defined parameters by their _identifier_. Things to remember here:

* A parameter or property is accessed with its _identifier_.
* Parameters decays to _underlying type_ (eg. formed from its _scope_ and its _type_).
* Properties decay to _type_.
* If explicit access to the _underlying type_ of parameters is required, `get()` can be used.
* One should not access `host` parameters inside a function to be executed on the `device`, and viceversa.

In other words, in the code above:

* `parameters.dev_atomics_velo` decays to `const unsigned*`.
* `parameters.dev_velo_track_hit_number` decays to `const unsigned*`.
* `parameters.dev_saxpy_output` decays to `float*`.
* `parameters.saxpy_scale_factor` decays to `float`, and has default value `2.f`.

The last thing remaining is to add the algorithm to a sequence, and run it.

* [This readme](configuration/readme.md) explains how to configure the algorithms in an HLT1 sequence.
