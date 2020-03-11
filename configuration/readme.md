Configuration
===============

`Allen` centers around the idea of running a __sequence of algorithms__ on input events. This sequence is predefined and will always be executed in the same order.
Some events from the input will be discarded throughout the execution, and only a fraction of them will be kept for further processing.

Allen is configured with the python scripts located in `generator`. Both the sequence of algorithms and the characteristics of individual algorithms are configurable. The properties of individual algorithms include
the input, output and properties.

Generate a configuration from within the `generator` directory with python3:

* Invoke `python3 /parse_algorithms.py`. The generated file `algorithms.py` contains information of the algorithms in the C++ code.

* You may `import algorithms` from a python3 shell and check with auto-complete the algorithms available and their options. Printing any one algorithm will tell you its parameters and properties. 
* You have some examples of sequences in the `configuration/generator/` folder, such as `VeloSequence.py`, `UTSequence.py` and so on.
* `python3 MakeDefaultConfigurations.py` will generate the configuration and store one header and one json file per sequence in the subdirectory `generated`.
* Taking as example the default HLT1 sequence: `Defaultequence.h` contains the C++ generated code to successfully compile the code. `DefaultSequence.json`  can be used to configure the Allen application when invoking it. 
* `ConfigurationGuide.json` contains all available options and their default values, for reference.

* Copy the generated `DefaultSequence.h` into `configuration/sequences/`, and the `DefaultSequence.json` into `configuration/constants/`. 
* Now you should be able to compile your sequence by issuing `cmake -DSEQUENCE=DefaultSequence .. && make`. 
* You can invoke the program with your options with `./Allen --configuration=../configuration/constants/Configuration.json`.
* In the case of calling Allen from Gaudi:
  * `export CMAKEFLAGS="-DSEQUENCE=YourOwnSequence.h"` before the call to `make configure`
  * set the "JSON" property of the RunAllen algorithm to the json file you just generated.
* Generate your own custom sequence along the same principles!

Enjoy!

### To do: add the allocation of host memory to a readme

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
