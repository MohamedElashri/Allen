Configuring the sequence of algorithms
===============

`Allen` centers around the idea of running a __sequence of algorithms__ on input events. This sequence is predefined and will always be executed in the same order.
Some events from the input will be discarded throughout the execution, and only a fraction of them will be kept for further processing.

Allen is configured with the python scripts located in `generator`. Both the sequence of algorithms and the characteristics of individual algorithms are configurable. The properties of individual algorithms include
the input, output and properties.

Explore the algorithms available and view their properties from within the `generator` directory:
Invoke `python3 /parse_algorithms.py`. The generated file `algorithms.py` contains information of the algorithms in the C++ code.
You may `import algorithms` from a python3 shell and check with auto-complete the algorithms available and their options, for example:

```sh=
foo@bar:~$ python3 parse_algorithms.py 
Generating algorithms.py...
File algorithms.py was successfully generated.
foo@bar:~$ python3
Python 3.6.5 (default, Jun 15 2019, 23:43:55) 
[GCC 8.2.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> import algorithms
>>> algorithms.velo_
algorithms.velo_calculate_number_of_candidates_t(  algorithms.velo_estimate_input_size_t(             algorithms.velo_pv_ip_t(
algorithms.velo_calculate_phi_and_sort_t(          algorithms.velo_fill_candidates_t(                 algorithms.velo_search_by_triplet_t(
algorithms.velo_consolidate_tracks_t(              algorithms.velo_kalman_filter_t(                   algorithms.velo_three_hit_tracks_filter_t(
algorithms.velo_copy_track_hit_number_t(           algorithms.velo_masked_clustering_t(   
```

Printing any one algorithm will tell you its parameters and properties:

```sh=
>>> algorithms.velo_calculate_phi_and_sort_t()
velo_calculate_phi_and_sort_t "velo_calculate_phi_and_sort_t" (
  host_number_of_selected_events_t = HostInput("host_number_of_selected_events_t", uint32_t), 
  host_total_number_of_velo_clusters_t = HostInput("host_total_number_of_velo_clusters_t", uint32_t), 
  dev_offsets_estimated_input_size_t = DeviceInput("dev_offsets_estimated_input_size_t", uint32_t), 
  dev_module_cluster_num_t = DeviceInput("dev_module_cluster_num_t", uint32_t), 
  dev_velo_cluster_container_t = DeviceInput("dev_velo_cluster_container_t", char), 
  dev_sorted_velo_cluster_container_t = DeviceOutput("dev_sorted_velo_cluster_container_t", char), 
  dev_hit_permutation_t = DeviceOutput("dev_hit_permutation_t", uint32_t), 
  dev_hit_phi_t = DeviceOutput("dev_hit_phi_t", half_t), 
  block_dim = Property(DeviceDimensions, {64, 1, 1}, block dimensions) = "")
```

You can also create an instance of the algorithm and auto-complete the parameters:
```sh=
>>> a = algorithms.ut_search_windows_t()
>>> a.
a.block_dim_y_t(                               a.dev_ut_selected_velo_tracks_t(               a.min_momentum_t(                              a.properties(
a.dev_offsets_all_velo_tracks_t(               a.dev_ut_windows_layers_t(                     a.min_pt_t(                                    a.requires_lines(
a.dev_offsets_velo_track_hit_number_t(         a.dev_velo_states_t(                           a.name(                                        a.y_tol_slope_t(
a.dev_ut_hit_offsets_t(                        a.filename(                                    a.namespace(                                   a.y_tol_t(
a.dev_ut_hits_t(                               a.host_number_of_reconstructed_velo_tracks_t(  a.original_name(                               
a.dev_ut_number_of_selected_velo_tracks_t(     a.host_number_of_selected_events_t(            a.parameters(                                  
>>> a.block_dim_y_t()
Property(uint32_t, 64, block dimension Y) = ""

```

Generate a configuration from within the `generator` directory with python3:

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


To understand the configuration in more detail, we let's take a look at how to configure
the same algorithm with different properties. As example we take the UT tracking,
with either loose or restricted cuts. The full code can be found in `generator/UTSequence.py`.

```clike=
 ut_search_windows = None
    compass_ut = None
    if restricted:
        ut_search_windows = ut_search_windows_t(
            min_momentum="1500.0", min_pt="300.0")
        compass_ut = compass_ut_t(
            max_considered_before_found="6",
            min_momentum_final="2500.0",
            min_pt_final="425.0")
    else:
        ut_search_windows = ut_search_windows_t(
            min_momentum="3000.0", min_pt="0.0")
        compass_ut = compass_ut_t(
            max_considered_before_found="16",
            min_momentum_final="0.0",
            min_pt_final="0.0")
```

In this case, the search windows for the pattern recognition step are set differently,
and the settings for the UT track reconstruction (compass_ut) also vary,
depending on whether `restricted` is true or false.

Alternatively, one can call the same algorithm twice in the same sequence, with different configurations.

```clike=
   ut_search_windows_restricted = ut_search_windows_t(
            min_momentum="1500.0", min_pt="300.0",
            dev_ut_windows_layers=dev_ut_windows_layers_restricted)
            
   ut_search_windows_loose = ut_search_windows_t(
            min_momentum="3000.0", min_pt="0.0",
            dev_ut_windows_layers=dev_ut_windows_layers_loose)
            
    ...
    
    ut_sequence = Sequence(
        ut_calculate_number_of_hits, prefix_sum_ut_hits, ut_pre_decode,
        ut_find_permutation, ut_decode_raw_banks_in_order,
        ut_select_velo_tracks, ut_search_windows_restricted,
        ut_search_windows_loose)
    
```
Then, one can add other algorithms afterwards, for example one taking as input `dev_ut_windows_layers_restricted`,
the other taking `dev_ut_windows_layers_loose`.


To find out how to write a trigger line in Allen and how to add it to the sequence, follow the instructions [here](../selections.md).

