.. _configure_sequence:

Configuring the sequence of algorithms
======================================

Allen centers around the idea of running a *sequence of algorithms* on input events. This sequence is predefined and will always be executed in the same order.

The sequence can be configured with python. Existing configurations can be browsed under `configuration/sequences`. The sequence name is the name of each individual file, without the `.py` extension, in that folder. For instance, some sequence names are `velo`, `veloUT`, or `hlt1_pp_default`.

The sequence can be chosen at runtime with the option `--sequence`. For instance::

    # Configure the VELO sequence
    ./Allen --sequence velo

    # Configure the ut sequence
    ./Allen --sequence veloUT

    # Configure the hlt1_pp_default sequence
    ./Allen --sequence hlt1_pp_default

The rest of this readme explains the workflow to generate a new sequence.

Creating a new sequence
-----------------------

In order to create a new sequence, head to `configuration/python/AllenSequences/` and create a new sequence file with extension `.py`.

You may reuse what exists already in `configuration/python/AllenConf/` and extend that. In order to create a new sequence, you should:

* Instantiate algorithms. Algorithm inputs must be assigned other algorithm outputs.
* Generate at least one CompositeNode with the algorithms we want to run.
* Generate the configuration with the `generate()` method.

As an example, let us add the SAXPY algorithm to a custom sequence. Start by including algorithms and the VELO sequence:

.. code-block:: python

  from AllenCore.algorithms import saxpy_t
  from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks
  from AllenConf.utils import initialize_number_of_events
  from PyConf.control_flow import CompositeNode
  from AllenCore.generator import generate, make_algorithm

  number_of_events = initialize_number_of_events()
  decoded_velo = decode_velo()
  velo_tracks = make_velo_tracks(decoded_velo)

`initialize_number_of_events`, `decode_velo` and `make_velo_tracks` are already defined functions that instantiate the relevant algorithms that
we will need for our example.

We should now add the SAXPY algorithm. We can use an interactive session to explore what it requires::

  >>> algorithms.saxpy_t.getDefaultProperties()
  OrderedDict([('host_number_of_events_t',
              DataHandle('host_number_of_events_t','R','unsigned int')),
             ('dev_number_of_events_t',
              DataHandle('dev_number_of_events_t','R','unsigned int')),
             ('dev_offsets_all_velo_tracks_t',
              DataHandle('dev_offsets_all_velo_tracks_t','R','unsigned int')),
             ('dev_offsets_velo_track_hit_number_t',
              DataHandle('dev_offsets_velo_track_hit_number_t','R','unsigned int')),
             ('dev_saxpy_output_t',
              DataHandle('dev_saxpy_output_t','W','float')),
             ('verbosity', ''),
             ('saxpy_scale_factor', ''),
             ('block_dim', '')])

The inputs should be passed into our sequence to be able to instantiate `saxpy_t`. Knowing which inputs to pass is up to the developer. For this one, let's just pass:

.. code-block:: python

  saxpy = make_algorithm(
    saxpy_t,
    name = "saxpy",
    host_number_of_events_t = number_of_events["host_number_of_events"],
    dev_number_of_events_t = number_of_events["dev_number_of_events"],
    dev_offsets_all_velo_tracks_t = velo_tracks["dev_offsets_all_velo_tracks"],
    dev_offsets_velo_track_hit_number_t = velo_tracks["dev_offsets_velo_track_hit_number"])

Finally, let's create a CompositeNode just with our algorithm inside, and generate the sequence:

.. code-block:: python

  saxpy_sequence = CompositeNode("Saxpy", [saxpy])
  generate(saxpy_sequence)

The final configuration file is therefore:

.. code-block:: python

  from AllenCore.algorithms import saxpy_t
  from AllenConf.velo_reconstruction import decode_velo, make_velo_tracks
  from AllenConf.utils import initialize_number_of_events
  from PyConf.control_flow import CompositeNode
  from AllenCore.generator import generate, make_algorithm

  number_of_events = initialize_number_of_events()
  decoded_velo = decode_velo()
  velo_tracks = make_velo_tracks(decoded_velo)

  saxpy = make_algorithm(
    saxpy_t,
    name = "saxpy",
    host_number_of_events_t = number_of_events["host_number_of_events"],
    dev_number_of_events_t = number_of_events["dev_number_of_events"],
    dev_offsets_all_velo_tracks_t = velo_tracks["dev_offsets_all_velo_tracks"],
    dev_offsets_velo_track_hit_number_t = velo_tracks["dev_offsets_velo_track_hit_number"])

  saxpy_sequence = CompositeNode("Saxpy", [saxpy])
  generate(saxpy_sequence)

Now, we can save this configuration as `configuration/python/AllenSequences/saxpy.py` and run it::

  ./Allen --sequence saxpy

The following text should appear as part of the run of the program, which indicates the algorithms that will be executed and the order in which they will run::

  Generated sequence represented as algorithms with execution masks:
    host_init_event_list_t/initialize_event_lists
    host_init_number_of_events_t/initialize_number_of_events
    data_provider_t/velo_banks
    velo_calculate_number_of_candidates_t/velo_calculate_number_of_candidates
    host_prefix_sum_t/prefix_sum_offsets_velo_candidates
    velo_estimate_input_size_t/velo_estimate_input_size
    host_prefix_sum_t/prefix_sum_offsets_estimated_input_size
    velo_masked_clustering_t/velo_masked_clustering
    velo_calculate_phi_and_sort_t/velo_calculate_phi_and_sort
    velo_search_by_triplet_t/velo_search_by_triplet
    velo_three_hit_tracks_filter_t/velo_three_hit_tracks_filter
    host_prefix_sum_t/prefix_sum_offsets_number_of_three_hit_tracks_filtered
    host_prefix_sum_t/prefix_sum_offsets_velo_tracks
    velo_copy_track_hit_number_t/velo_copy_track_hit_number
    host_prefix_sum_t/prefix_sum_offsets_velo_track_hit_number
    saxpy_t/saxpy

To find out how to write a trigger line in Allen and how to add it to the sequence, follow :ref:`selections`.
