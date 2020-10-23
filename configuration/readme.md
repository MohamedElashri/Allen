Configuring the sequence of algorithms
======================================

Allen centers around the idea of running a __sequence of algorithms__ on input events. This sequence is predefined and will always be executed in the same order.

The sequence can be configured with python. Existing configurations can be browsed under `configuration/sequences`. The sequence name is the name of each individual file, without the `.py` extension, in that folder. For instance, some sequence names are `velo`, `ut`, or `hlt1_pp_default`.

The sequence can be chosen _at compile time_ with the cmake option `SEQUENCE`, and passing a concrete sequence name. For instance:

    # Configure the VELO sequence
    cmake -DSEQUENCE=velo ..

    # Configure the ut sequence
    cmake -DSEQUENCE=ut ..

    # Configure the hlt1_pp_default sequence (by default)
    cmake ..

The rest of this readme explains the workflow to generate a new sequence.

Inspecting algorithms
---------------------

In order to generate a new sequence, python 3 and (cvmfs and CentOS 7, or clang 9 or higher) are required.

It is possible to inspect all algorithms defined in Allen interactively by using the _python view_ that the parser automatically generates. From a build directory:

```sh
foo@bar:build$ cmake ..
foo@bar:build$ cd sequences
foo@bar:build/sequences$ python3
Python 3.8.2 (default, Feb 28 2020, 00:00:00) 
[GCC 10.0.1 20200216 (Red Hat 10.0.1-0.8)] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> from definitions import algorithms
>>>
```

Now, you can inspect any existing algorithm. For instance, all algorithms starting with `velo_`:

```sh
>>> algorithms.velo_
algorithms.velo_calculate_number_of_candidates_t(  algorithms.velo_kalman_filter_t(
algorithms.velo_calculate_phi_and_sort_t(          algorithms.velo_masked_clustering_t(
algorithms.velo_consolidate_tracks_t(              algorithms.velo_pv_ip_t(
algorithms.velo_copy_track_hit_number_t(           algorithms.velo_search_by_triplet_t(
algorithms.velo_estimate_input_size_t(             algorithms.velo_three_hit_tracks_filter_t(
```

One can see the input and output parameters and properties of an algorithm by just printing the class representation of an algorithm (ie. _without parentheses_). For instance:

```sh
>>> algorithms.velo_calculate_number_of_candidates_t
class AlgorithmRepr : DeviceAlgorithm
 inputs: ('host_number_of_events_t', 'dev_event_list_t', 'dev_velo_raw_input_t', 'dev_velo_raw_input_offsets_t')
 outputs: ('dev_number_of_candidates_t',)
 properties: ('block_dim_x',)
```

Creating a new sequence
-----------------------

In order to create a new sequence, head to `configuration/sequences` and create a new sequence file with extension `.py`.

You may reuse what exists already in `definitions` and extend that instead. In order to create a new sequence, you should:

* Instantiate (ie. _with parentheses_) algorithms. Algorithm inputs must be assigned other algorithm outputs.
* Create a `Sequence` object with the desired algorithm instances in order of execution.
* `Sequences` can also be composed or extended.
* Generate the configuration with the `generate()` method of the `Sequence` instance.

As an example, let us add the SAXPY algorithm to a custom sequence. Start by including algorithms and the VELO sequence:

```sh
from definitions.algorithms import *
from definitions.VeloSequence import VeloSequence

velo_sequence = VeloSequence()
```

`velo_sequence` contains a `Sequence` object with all algorithms defined therein. The individual algorithms are still accessible with `__get_item__` and the algorithm name (like a dictionary).

We should now add the SAXPY algorithm. We can use the interactive session to explore what it requires:

```sh
>>> saxpy_t
class AlgorithmRepr : DeviceAlgorithm
 inputs: ('host_number_of_events_t', 'dev_number_of_events_t', 'dev_offsets_all_velo_tracks_t', 'dev_offsets_velo_track_hit_number_t')
 outputs: ('dev_saxpy_output_t',)
 properties: ('saxpy_scale_factor', 'block_dim')
```

The inputs should be passed into our sequence to be able to instantiate `saxpy_t`. Knowing which inputs to pass is up to the developer. For this one, let's just pass:

```sh
saxpy = saxpy_t(
  name = "saxpy",
  host_number_of_events_t = velo_sequence["initialize_lists"].host_number_of_events_t(),
  dev_number_of_events_t = velo_sequence["initialize_lists"].dev_number_of_events_t(),
  dev_offsets_all_velo_tracks_t = velo_sequence["velo_copy_track_hit_number"].dev_offsets_all_velo_tracks_t(),
  dev_offsets_velo_track_hit_number_t = velo_sequence["prefix_sum_offsets_velo_track_hit_number"].dev_output_buffer_t())
```

Finally, let's extend the `velo_sequence` with our newly created algorithm, and generate the sequence:

```sh
extend_sequence(velo_sequence, saxpy).generate()
```

The final configuration file is therefore:

```sh
from definitions.algorithms import *
from definitions.VeloSequence import VeloSequence

velo_sequence = VeloSequence()

saxpy = saxpy_t(
  name = "saxpy",
  host_number_of_events_t = velo_sequence["initialize_lists"].host_number_of_events_t(),
  dev_number_of_events_t = velo_sequence["initialize_lists"].dev_number_of_events_t(),
  dev_offsets_all_velo_tracks_t = velo_sequence["velo_copy_track_hit_number"].dev_offsets_all_velo_tracks_t(),
  dev_offsets_velo_track_hit_number_t = velo_sequence["prefix_sum_offsets_velo_track_hit_number"].dev_output_buffer_t())

extend_sequence(velo_sequence, saxpy).generate()
```

Now, we can save this configuration as `configuration/sequences/saxpy.py`, and build it and run it:

```sh
mkdir build
cd build
cmake -DSEQUENCE=saxpy ..
make
./Allen
```

To find out how to write a trigger line in Allen and how to add it to the sequence, follow the instructions [here](../selections.md).
