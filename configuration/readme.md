Configuration
===============

Allen is configured with the python scripts located in `generator`. 

In order to generate a configuration, from the `configuration/generator/` folder follow the next steps:

* Invoke `./parse_algorithms.py`. The generated file `algorithms.py` contains information of the algorithms in the C++ code.

* Write your own configuration. You may `import algorithms` from a python shell and check with auto-complete the algorithms available and their options. Printing any one algorithm will tell you its parameters and properties. You have also some examples in the `configuration/generator/` folder, such as `VeloSequence.py`, `UTSequence.py` and so on.

* Invoke the `generate` method of a sequence. This will generate three files: A `ConfiguredSequence.h` containing the C++ generated code to successfully compile the code. A `Configuration.json` file, which can be used to configure the application when invoking it. Finally, a `ConfigurationGuide.json`, with all available options and their default values, for reference.

* Copy the generated `ConfiguredSequence.h` onto `configuration/sequences/`, and the `Configuration.json` onto `configuration/constants/`. Now you should be able to compile your sequence by issuing `cmake -DSEQUENCE=ConfiguredSequence .. && make`. You can invoke the program with your options with `./Allen --configuration=../configuration/constants/Configuration.json`.

Enjoy!



### Integrating the algorithm in the sequence

`Allen` centers around the idea of running a __sequence of algorithms__ on input events. This sequence is predefined and will always be executed in the same order.

Some events from the input will be discarded throughout the execution, and only a fraction of them will be kept for further processing. That is conceptually the idea behind the _High Level Trigger 1_ stage of LHCb, and is what is intended to achieve with this project.

Therefore, we need to add our algorithm to the sequence of algorithms. First, make the folder visible to CMake by editing the file `stream/CMakeLists.txt` and adding:

```clike
include_directories(${CMAKE_SOURCE_DIR}/cuda/test/saxpy/include)
```

Then, add the following include to `stream/setup/include/ConfiguredSequence.cuh`:

```clike
#include "Saxpy.cuh"
```

Now, we are ready to add our algorithm to a sequence. All available sequences live in the folder `configuration/sequences/`. The sequence to execute can be chosen at compile time, by appending the name of the desired sequence to the cmake call: `cmake -DSEQUENCE=DefaultSequence ..`. For now, let's just edit the `DefaultSequence`. Add the algorithm to `configuration/sequences/DefaultSequence.h` as follows:

```clike
/**
 * Specify here the algorithms to be executed in the sequence,
 * in the expected order of execution.
 */
SEQUENCE_T(
  ...
  prefix_sum_reduce_velo_track_hit_number_t,
  prefix_sum_single_block_velo_track_hit_number_t,
  prefix_sum_scan_velo_track_hit_number_t,
  consolidate_tracks_t,
  saxpy_t,
  ...
)
```

Keep in mind the order matters, and will define when your algorithm is scheduled. In this case, we have chosen to add it after the algorithm identified by `consolidate_tracks_t`.

Next, we need to define the arguments to be passed to our function. We need to define them in order for the dynamic scheduling machinery to properly work - that is, allocate what is needed only when it's needed, and manage the memory for us.

We will distinguish arguments just passed by value from pointers to device memory. We don't need to schedule those simply passed by value like `n` and `a`. We care however about `x` and `y`, since they require some reserving and freeing in memory.

In the algorithm definition we used the arguments `dev_x` and `dev_y`. We need to define the arguments, to make them available to our algorithm. Let's add these types to the common arguments, in `stream/setup/include/ArgumentsCommon.cuh`:

```clike
...
ARGUMENT(dev_x, float)
ARGUMENT(dev_y, float)
```

Optionally, some types are required to live throughout the whole sequence since its creation. An argument can be specified to be persistent in memory by adding it to the `output_arguments_t` tuple, in `AlgorithmDependencies.cuh`:

```clike
/**
 * @brief Output arguments, ie. that cannot be freed.
 * @details The arguments specified in this type will
 *          be kept allocated since their first appearance
 *          until the end of the sequence.
 */
typedef std::tuple<
  dev_atomics_storage,
  dev_velo_track_hit_number,
  dev_velo_track_hits,
  dev_atomics_veloUT,
  dev_veloUT_tracks,
  dev_scifi_tracks,
  dev_n_scifi_tracks
> output_arguments_t;
```

### Preparing and invoking the algorithms in the sequence

Now all the pieces are in place, we are ready to prepare the algorithm and do the actual invocation.

First go to `stream/sequence/include/HostBuffers.cuh` and add the saxpy host memory pointer:

```clike
  ...
    
  // Pinned host datatypes
  uint* host_velo_tracks_atomics;
  uint* host_velo_track_hit_number;
  uint* host_velo_track_hits;
  uint* host_total_number_of_velo_clusters;
  uint* host_number_of_reconstructed_velo_tracks;
  uint* host_accumulated_number_of_hits_in_velo_tracks;
  uint* host_accumulated_number_of_ut_hits;

  // Saxpy
  int saxpy_N = 1<<20;
  float *host_x, *host_y;

  ...
```

Reserve that host memory in `stream/sequence/src/HostBuffers.cu`:

```clike
  ...
    
  cudaCheck(cudaMallocHost((void**)&host_velo_tracks_atomics, (2 * max_number_of_events + 1) * sizeof(int)));
  cudaCheck(cudaMallocHost((void**)&host_velo_track_hit_number, max_number_of_events * VeloTracking::max_tracks * sizeof(uint)));
  cudaCheck(cudaMallocHost((void**)&host_velo_track_hits, max_number_of_events * VeloTracking::max_tracks * VeloTracking::max_track_size * sizeof(Velo::Hit)));
  cudaCheck(cudaMallocHost((void**)&host_total_number_of_velo_clusters, sizeof(uint)));
  cudaCheck(cudaMallocHost((void**)&host_number_of_reconstructed_velo_tracks, sizeof(uint)));
  cudaCheck(cudaMallocHost((void**)&host_accumulated_number_of_hits_in_velo_tracks, sizeof(uint)));
  cudaCheck(cudaMallocHost((void**)&host_veloUT_tracks, max_number_of_events * VeloUTTracking::max_num_tracks * sizeof(VeloUTTracking::TrackUT)));
  cudaCheck(cudaMallocHost((void**)&host_atomics_veloUT, VeloUTTracking::num_atomics * max_number_of_events * sizeof(int)));
  cudaCheck(cudaMallocHost((void**)&host_accumulated_number_of_ut_hits, sizeof(uint)));
  cudaCheck(cudaMallocHost((void**)&host_accumulated_number_of_scifi_hits, sizeof(uint)));
  
  // Saxpy memory allocations
  cudaCheck(cudaMallocHost((void**)&host_x, saxpy_N * sizeof(float)));
  cudaCheck(cudaMallocHost((void**)&host_y, saxpy_N * sizeof(float)));

  ...
```

Finally, create a visitor for your newly created algorithm. Create a containing folder structure for it in `stream/visitors/test/src/`, and a new file inside named `SaxpyVisitor.cu`. Insert the following code inside:

```clike
#include "SequenceVisitor.cuh"
#include "Saxpy.cuh"

template<>
void SequenceVisitor::set_arguments_size<saxpy_t>(
  saxpy_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  // Set arguments size
  int saxpy_N = 1<<20;
  arguments.set_size<dev_x>(saxpy_N);
  arguments.set_size<dev_y>(saxpy_N);
}

template<>
void SequenceVisitor::visit<saxpy_t>(
  saxpy_t& state,
  const saxpy_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  // Saxpy test
  int saxpy_N = 1<<20;
  for (int i = 0; i < saxpy_N; i++) {
    host_buffers.host_x[i] = 1.0f;
    host_buffers.host_y[i] = 2.0f;
  }

  // Copy memory from host to device
  cudaCheck(cudaMemcpyAsync(
    arguments.begin<dev_x>(),
    host_buffers.host_x,
    saxpy_N * sizeof(float),
    cudaMemcpyHostToDevice,
    cuda_stream
  ));

  cudaCheck(cudaMemcpyAsync(
    arguments.begin<dev_y>(),
    host_buffers.host_y,
    saxpy_N * sizeof(float),
    cudaMemcpyHostToDevice,
    cuda_stream
  ));

  // Setup opts for kernel call
  state.set_opts(dim3((saxpy_N+255)/256), dim3(256), cuda_stream);
  
  // Setup arguments for kernel call
  state.set_arguments(
    arguments.begin<dev_x>(),
    arguments.begin<dev_y>(),
    saxpy_N,
    2.0f
  );

  // Kernel call
  state.invoke();

  // Retrieve result
  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_y,
    arguments.begin<dev_y>(),
    arguments.size<dev_y>(),
    cudaMemcpyDeviceToHost,
    cuda_stream
  ));

  // Wait to receive the result
  cudaEventRecord(cuda_generic_event, cuda_stream);
  cudaEventSynchronize(cuda_generic_event);

  // Check the output
  float maxError = 0.0f;
  for (int i=0; i<saxpy_N; i++) {
    maxError = std::max(maxError, abs(host_buffers.host_y[i]-4.0f));
  }
  info_cout << "Saxpy max error: " << maxError << std::endl << std::endl;
}
```

As a last step, add the visitor to `stream/CMakeLists.txt`:

```clike
...
file(GLOB stream_visitors_test "visitors/test/src/*cu")
...
add_library(Stream STATIC
${stream_visitors_test}
...
```

We can compile the code and run the program `./Allen`. If everything went well, the following text should appear:

```
Saxpy max error: 0.00
```

The cool thing is your algorithm is now part of the sequence. You can see how memory is managed, taking into account your algorithm, and how it changes on every step by appending the `-p` option: `./Allen -p`

```
Sequence step 13 "saxpy_t" memory segments (MiB):
dev_velo_track_hit_number (0.01), unused (0.05), dev_atomics_storage (0.00), unused (1.30), dev_velo_track_hits (0.26), dev_x (4.00), dev_y (4.00), unused (1014.39), 
Max memory required: 9.61 MiB
```

Adding configurable parameters
==============================

To allow a parameter to be configurable via the JSON configuration interface, a `Property` must be
added to the corresponding `ALGORITHM` call. This makes uses of variadic macros so multiple `Property`
objects can be included and will be appended verbatim to the class definition written by the `ALGORITHM` macro.
For example, the following code will add two properties to the `search_by_triplet` algorithm:

```
ALGORITHM(search_by_triplet,
          velo_search_by_triplet_t,
          ARGUMENTS(
            dev_velo_cluster_container,
            ...
            dev_rel_indices),
          Property<float> m_tol {this,
                                 "forward_phi_tolerance",
                                 Configuration::velo_search_by_triplet_t::forward_phi_tolerance,
                                 0.052f,
                                 "tolerance"};
          Property<float> m_scat {this,
                                  "max_scatter_forwarding",
                                  Configuration::velo_search_by_triplet_t::max_scatter_forwarding,
                                  0.1f,
                                  "scatter forwarding"};
          )
```

The arguments passed to the `Property` constructor are
* the `Algorithm` that "owns" it;
* the name of the property in the JSON configuration;
* the underlying variable - this must be in `__constant__` memory for regular properties (see below);
* the default value of the property;
* a description of the property.

As the underlying parameters make use of GPU constant memory, they may not be defined within the
algorithm's class. They should instead be placed inside of namespace of the same name within the
`Configuration` namespace. For the example above, the following needs to be added to the header file:

```
namespace Configuration {
  namespace velo_search_by_triplet_t {
    // Forward tolerance in phi
    extern __constant__ float forward_phi_tolerance;
    // Max scatter for forming triplets (seeding) and forwarding
    extern __constant__ float max_scatter_forwarding;
  } // namespace velo_search_by_triplet_t
} // namespace Configuration
```

and the following to the code file:
```
__constant__ float Configuration::velo_search_by_triplet_t::forward_phi_tolerance;
__constant__ float Configuration::velo_search_by_triplet_t::max_scatter_forwarding;
```

Finally, the following can be added to the configuration file (default: `configuration/constants/default.json`)
to configure the values of these parameters at runtime:
```
"velo_search_by_triplet_t": {"forward_phi_tolerance" : "0.052", "max_scatter_forwarding" : "0.1"}
```

Derived properties
------------------

For properties derived from other configurable properties, the `DerivedProperty` class may be used:

```
Property<float> m_slope {this,
                         "sigma_velo_slope",
                         Configuration::compass_ut_t::sigma_velo_slope,
                         0.010f * Gaudi::Units::mrad,
                         "sigma velo slope [radians]"};
DerivedProperty<float> m_inv_slope {this,
                                    "inv_sigma_velo_slope",
                                    Configuration::compass_ut_t::inv_sigma_velo_slope,
                                    Configuration::Relations::inverse,
                                    std::vector<Property<float>*> {&this->m_slope},
                                    "inv sigma velo slope"};
```

Here, the value of the `m_inv_slope` property is determined by the function and the
vector of properties given in the third and fourth arguments. Additional functions
may be added to the `Configuration::Relations` and defined in `stream/gear/src/Configuration.cu`.
All functions take a vector of properties as an argument, to allow for functions of an
arbitrary number of properties.

CPU properties
--------------

Regular properties are designed to be used in GPU algorithms and are stored
in GPU constant memory with a cached copy within the `Property` class.
For properties that are only needed on the CPU, e.g. grid and block dimensions,
a `CPUProperty` can be used, which only stores the configured value internally.
This is also useful for properties tht are only needed when first configuring the
algorithm, such as properties only used in the visitor class.
Note that regular properties may also be used in this case
(e.g. `../stream/visitors/velo/src/SearchByTripletVisitor.cu` accesses non-CPU properties)
but if a property is *only* needed on the CPU then there is a reduced overhead in using a `CPUProperty`.

These are defined in the same way as a `Property` but take one fewer argument as there is no underlying
constant memory object to reference.

```
CPUProperty<std::array<int, 3>> m_block_dim {this, "block_dim", {32, 1, 1}, "block dimensions"};
CPUProperty<std::array<int, 3>> m_grid_dim {this, "grid_dim", {1, 1, 1}, "grid dimensions"};
```

Shared properties
-----------------

For properties that are shared between multiple top-level algorithms, it may be preferred
to keep the properties in a neutral location. This ensures that properties are configured
regardless of which algorithms are used in the configured sequence and can be achieved by
using a `SharedProperty`.

Shared properties are owned by a `SharedPropertySet` rather than an `Algorithm`
and example of which is given below.

```
#include "Configuration.cuh"

namespace Configuration {
  namespace example_common {
    extern __constant__ float param;
  }
}

struct ExampleConfiguration : public SharedPropertySet {
  ExampleConfiguration() = default;
  constexpr static auto name{ "example_common" };
private:
  Property<float> m_par{this, "param", Configuration::example_common::param, 0., "an example parameter"};
};
```

This may be used by any algorithm by including the header and adding the following line
to the end of the arguments of the `ALGORITHM` call.

```
SharedProperty<float> m_shared{this, "example_common", "param"};
```

These must also be plumbed in to `Configuration::getSharedPropertySet` in `stream/gear/src/Configuration.cu`
to allow the property set to be found by algorithms.
 