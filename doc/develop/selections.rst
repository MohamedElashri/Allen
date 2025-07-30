.. _selections:

Writing selections
======================
This tutorial will cover adding trigger selections to Allen using the
main reconstruction sequence.

Line execution
^^^^^^^^^^^^^^^^^^^^^^^

A line is a function that take some object list as input and returns a decision (boolean) for each object.
The decision can be prescaled and postscaled per event. The prescaler runs before the line, if the decision
of the prescaler is false, the line function will not be executed for that event. The postscaler runs after the line,
it will not affect the line function itself but only the output decision. This distinction is important if the line is
used for monitoring or filling tuples and for performances. If a line need to run over a lot of objects, tuning
the prescaler can make a difference in the throughput of the line.

Types of selections
^^^^^^^^^^^^^^^^^^^^^^^
Selections are fully configurable algorithms in Allen. Lines that select events
based on basic or composite particles must have a device input
`dev_particle_container_t` that is an `Allen::MultiEventContainer
<https://gitlab.cern.ch/lhcb/Allen/-/blob/master/device/event_model/common/include/MultiEventContainer.cuh>`_.
For convenience, there are some predefined line types.

OneTrackLine
------------
These lines trigger on basic particles with no decay products. In most cases,
this means triggering on Kalman-filtered long tracks. The input
`dev_particle_container_t` must be an `Allen::MultiEventBasicParticles`. Basic
particle properties are accessed via the `BasicParticle
<https://gitlab.cern.ch/lhcb/Allen/-/blob/master/device/event_model/common/include/ParticleTypes.cuh>`_
view. This view provides access to the track state (including
momentum), lepton ID, and the associated PV (including e.g. IP, IP chi2).

CompositeParticleLine
---------------------
These lines trigger on composite particles composed of other basic or composite
particles. In most cases, this means triggering on 2-track secondary vertices.
The input `dev_particle_container_t` must be an
`Allen::MultiEventCompositeParticles`. Composite particle properties are
accessed via the `CompositeParticle <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/device/event_model/common/include/ParticleTypes.cuh>`_
view. This view provides access to vertex fit results, the associated PV
(including e.g. FD, FD chi2), and the child particles (`BasicParticle` s and/or
`CompositeParticle` s).

EventLine
---------
A line that executes once per event.

ODINLine
--------
An EventLine that selects events based on information from the ODIN raw bank.

Custom line
-----------
A custom selection can trigger on any input data, and can either be based on
event-level information, or on more specific information.

Adding a new selection
^^^^^^^^^^^^^^^^^^^^^^
Choosing the right directory
----------------------------
HLT1 selection lines live in the directory  `device/selections/lines <https://gitlab.cern.ch/lhcb/Allen/-/tree/master/device/selections/lines>`_ and are grouped into directories based on the selection purpose. Currently, the following subdirectories exist:

* SMOG2
* calibration (includes alignment)
* charm
* electron
* inclusive_hadron
* muon
* monitoring
* photon

If your new selection fits into any of these categories, please add it in the respective directory. If not, feel free to create a new one and discuss in your merge request why you believe a new directory is required.

Every sub-directory contains a `include` and a `src` directory where the header and source files are placed.

Creating a selection
--------------------
Selections are of type `SelectionAlgorithm`, that must in addition inherit from a line type.
Like with any other `Algorithm`, a `SelectionAlgorithm` can have inputs,
outputs and properties. However, certain inputs and outputs are assumed and must be defined:

(Total) number of events::

   HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events;

Event list to which the selection is applied::

  MASK_INPUT(dev_event_list_t);

Type-erased parameters to be passed to the line functions for delayed line processing::

  HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;

In case that the selection algorithm requires a `dev_particle_container_t`, then the `host_fn_parameters_t` should be defined as follows instead::

  HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char) host_fn_parameters;

Line data that will be passed to an upcoming algorithm (usually `gather_selections_t`). It contains copies of various properties and inputs, such as the pre and post scaler::

  HOST_OUTPUT(host_line_data_t, LineData) host_line_data;


In order to define a selection algorithm, one must define a struct as follows:

.. code-block:: c++

    struct "name_of_algorithm" : public SelectionAlgorithm, Parameters, "line_type"<"name_of_algorithm", Parameters>

In the above, `"name_of_algorithm"` is the name of the algorithm, and `"line_type"` can be either `Line` for a completely customizable line, or any of the predefined line types (such as `OneTrackLine`, `CompositeParticleLine`, `ODINLine`, etc.). Please note that `"name_of_algorithm"` appears twice in the selection algorithm definition.

A `SelectionAlgorithm` can contain the following:

.. code-block:: c++

   using iteration_t = LineIteration::event_iteration_tag;

Used if each selection is to be applied exactly once per event (eg. a lumi line).

.. code-block:: c++

   static unsigned get_decisions_size(ArgumentReferences<Parameters>& arguments) const { ... }

A function that returns the size of the decisions container.

.. code-block:: c++

   __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number) const { ... }

A function that returns the offset of the decisions container for a given `event_number`

.. code-block:: c++

    __device__ static std::tuple<"configurable_types">
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i) const {
        ...
        return std::forward_as_tuple("instances");
    }

A function that gets the `i`th input of `event_number`, and returns it as a tuple. The `"configurable_types"` can be anything. The return statement of the function is suggested to be a `return std::forward_as_tuple()` with the `"instances"` of the desired objects. The return type of this function will be used as the input of the `select` function.

.. code-block:: c++

  __device__ static bool select(
      const Parameters& parameters,
      std::tuple<"configurable_types"> input) const
  {
      ...
      return [true/false];
  }

The function that performs the selection for a single input. The type of the input must match the `"configurable_types"` of the `get_input` function. It returns a boolean with the decision output. The `select` function must be defined as static in the header file.

* Optional: `unsigned get_block_dim_x(const ArgumentReferences<Parameters>&) const { ... }`: Defines the number of threads the selection will be performed with.

In addition, lines must be instantiated in their source file definition:

* `INSTANTIATE_LINE("name_of_algorithm", "parameters_of_algorithm")`

Lines are automatically parallelized with `threadIdx.x` (see the default setting in `Line.cuh <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/device/selections/line_types/include/Line.cuh>`_. The 1D block dimension is configurable however by providing a different implementation of `Derived::get_block_dim_x`.

Below are four examples of lines.

OneTrackLine example
--------------------
As an example, we'll create a line that triggers on highly displaced,
high-pT single long tracks. It will be of type `OneTrackLine`. We will first create the
header.

.. code-block:: c++

  #pragma once

  #include "AlgorithmTypes.cuh"
  #include "OneTrackLine.cuh"

  namespace example_one_track_line {
    struct Parameters {
      // Commonly required inputs, outputs
      HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
      MASK_INPUT(dev_event_list_t);
      HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
      // Line-specific inputs
      HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
      DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventBasicParticles) dev_particle_container_t;
      HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char) host_fn_parameters;
    };

    // SelectionAlgorithm definition
    struct example_one_track_line_t : public SelectionAlgorithm, Parameters, OneTrackLine<example_one_track_line_t, Parameters> {
      // Selection function.
      __device__ static bool select(const Parameters& parameters, std::tuple<const Allen::Views::Physics::BasicParticle> input);

    private:
      // Line-specific properties
      Property<float> m_minPt {this, "minPt", 10000.0f * Allen::Units::MeV, "minPt description"};
      Property<float> m_minIPChi2 {this, "minIPChi2", 25.0f, "minIPChi2 description"};
    };
  } // namespace example_one_track_line

And the then the source:

.. code-block:: c++

  #include "ExampleOneTrackLine.cuh"

  // Explicit instantiation of the line
  INSTANTIATE_LINE(example_one_track_line::example_one_track_line_t, example_one_track_line::Parameters)

  __device__ bool example_one_track_line::example_one_track_line_t::select(
    const Parameters& parameters,
    std::tuple<const Allen::Views::Physics::BasicParticle> input)
  {
    const auto& track = std::get<0>(input);
    const bool decision = track.state().pt() > parameters.minPt && track.ip_chi2() > parameters.minIPChi2;
    return decision;
  }

Note that since the type of this line was the preexisting (`OneTrackLine`), it was not
necessary to define any function other than `select`.

CompositeParticleLine example
-----------------------------
Here we'll create an example of a 2-long-track line that selects displaced
secondary vertices with no postscale. This line inherits from `CompositeParticleLine`. We'll create a header with the following contents:

.. code-block:: c++

  #pragma once

  #include "AlgorithmTypes.cuh"
  #include "CompositeParticleLine.cuh"

  namespace example_two_track_line {
    struct Parameters {
      // Commonly required inputs, outputs and properties
      HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
      MASK_INPUT(dev_event_list_t);
      HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
      // Line-specific inputs and properties
      HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
      DEVICE_INPUT(dev_particle_container_t, Allen::Views::Physics::MultiEventCompositeParticles) dev_particle_container;
      HOST_OUTPUT_WITH_DEPENDENCIES(host_fn_parameters_t, DEPENDENCIES(dev_particle_container_t), char) host_fn_parameters;
    };

    // SelectionAlgorithm definition
    struct example_two_track_line_t : public SelectionAlgorithm, Parameters, CompositeParticleLine<example_two_track_line_t, Parameters> {
      // Selection function.
      __device__ static bool select(const Parameters&, std::tuple<const Allen::Views::Physics::CompositeParticle>);

    private:
      // Line-specific properties
      Property<float> m_minComboPt {this, "minComboPt", 2000.0f * Allen::Units::MeV, "minComboPt description"};
      Property<float> m_minTrackPt {this, "minTrackPt", 500.0f * Allen::Units::MeV, "minTrackPt description"};
      Property<float> m_minTrackIPChi2 {this, "minTrackIPChi2", 25.0f, "minTrackIPChi2 description"};
    };

  } // namespace example_two_track_line

And a source with the following:

.. code-block:: c++

  #include "ExampleCompositeParticleLine.cuh"

  INSTANTIATE_LINE(example_two_track_line::example_two_track_line_t, example_two_track_line::Parameters)

  __device__ bool example_two_track_line::example_two_track_line_t::select(
    const Parameters& parameters,
    std::tuple<const Allen::Views::Physics::CompositeParticle> input)
  {
    const auto& particle = std::get<0>(input);

    // Make sure the vertex fit succeeded.
    if (particle.vertex().chi2() < 0) {
      return false;
    }

    const bool decision = particle.vertex().pt() > parameters.minComboPt &&
      particle.minpt() > parameters.minTrackPt &&
      particle.minipchi2() > parameters.minTrackIPChi2;
    return decision;
  }

EventLine example
-----------------
Now we'll define a line that selects events with at least 1 reconstructed VELO track. This line runs once per event, so it inherits from `EventLine`.
This time, we will need to define not only the `select` function, but also the `get_input` function, as we need custom data to feed into our line (the number of tracks in an event).

The header `monitoring/include/VeloMicroBiasLine.cuh <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/device/selections/lines/monitoring/include/VeloMicroBiasLine.cuh>`_ is as follows:

.. code-block:: c++

  #pragma once

  #include "AlgorithmTypes.cuh"
  #include "EventLine.cuh"
  #include "VeloConsolidated.cuh"

  namespace velo_micro_bias_line {
    struct Parameters {
      // Commonly required inputs, outputs and properties
      HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
      MASK_INPUT(dev_event_list_t);
      HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
      HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;
       post_scaler_hash_string;
      // Line-specific inputs and properties
      DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
      DEVICE_INPUT(dev_offsets_velo_tracks_t, unsigned) dev_offsets_velo_tracks;
      DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned) dev_offsets_velo_track_hit_number;
    };

    struct velo_micro_bias_line_t : public SelectionAlgorithm, Parameters, EventLine<velo_micro_bias_line_t, Parameters> {
      __device__ static std::tuple<const unsigned>
      get_input(const Parameters& parameters, const unsigned event_number);

      __device__ static bool select(const Parameters& parameters, std::tuple<const unsigned> input);

    private:
      // Line-specific properties
      Property<unsigned> m_min_velo_tracks {this, "min_velo_tracks", 1, "Minimum number of VELO tracks"};
    };
  } // namespace velo_micro_bias_line

Note that we have added three inputs to obtain VELO track information (`dev_offsets_velo_tracks_t`, `dev_offsets_velo_track_hit_number_t` and `dev_number_of_events_t`). Finally, `get_input` is declared as well, which we will have to define in the source file. `get_input` will return a `std::tuple<const unsigned>`, which is the type of the `input` argument in `select`.

The source file `monitoring/src/VeloMicroBiasLine.cu` looks as follows:

.. code-block:: c++

  #include "VeloMicroBiasLine.cuh"

  // Explicit instantiation
  INSTANTIATE_LINE(velo_micro_bias_line::velo_micro_bias_line_t, velo_micro_bias_line::Parameters)

  __device__ std::tuple<const unsigned>
  velo_micro_bias_line::velo_micro_bias_line_t::get_input(const Parameters& parameters, const unsigned event_number)
  {
    Velo::Consolidated::ConstTracks velo_tracks {
      parameters.dev_offsets_velo_tracks, parameters.dev_offsets_velo_track_hit_number, event_number, parameters.dev_number_of_events[0]};
    const unsigned number_of_velo_tracks = velo_tracks.number_of_tracks(event_number);
    return std::forward_as_tuple(number_of_velo_tracks);
  }

  __device__ bool velo_micro_bias_line::velo_micro_bias_line_t::select(
    const Parameters& parameters,
    std::tuple<const unsigned> input)
  {
    const auto number_of_velo_tracks = std::get<0>(input);
    return number_of_velo_tracks >= parameters.min_velo_tracks;
  }

`get_input` gets the number of VELO tracks and returns it, and `select` will select only events with VELO tracks.

CustomLine example
------------------
Finally, we'll define a line that runs on every velo track. Since this is a completely custom line, we need to define all the functions of the line, i.e. `select`, `get_input`, `get_decisions_size` and `offset`.
In addition, we also need to add some properties to the line.

The header `ExampleOneVeloTrackLine.cuh` is as follows:

.. code-block:: c++

  #pragma once

  #include "AlgorithmTypes.cuh"
  #include "Line.cuh"
  #include "VeloConsolidated.cuh"

  namespace example_one_velo_track_line {
    struct Parameters {
      // Commonly required inputs, outputs and properties
      HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
      MASK_INPUT(dev_event_list_t);
      HOST_OUTPUT(host_line_data_t, LineData) host_line_data;
      HOST_OUTPUT(host_fn_parameters_t, char) host_fn_parameters;
      // Line-specific inputs and properties
      DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
      DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
      DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned) dev_velo_track_hit_number;
    };

    // SelectionAlgorithm definition
    struct example_one_velo_track_line_t : public SelectionAlgorithm, Parameters, Line<example_one_velo_track_line_t, Parameters> {

        // Offset function
        __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number);

        //Get decision size function
        static unsigned get_decisions_size(ArgumentReferences<Parameters>& arguments);

        // Get input function
        __device__ static std::tuple<const unsigned> get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);

        // Selection function
        __device__ static bool select(const Parameters& parameters, std::tuple<const unsigned> input);

    private:
      // Line-specific properties
      Property<unsigned> m_minNHits {this, "minNHits", 0, "min number of hits of velo track"};
    };
  } // namespace example_one_velo_track_line

Note that we have added some inputs and one property.

The source file looks as follows:

.. code-block:: c++

  #include "ExampleOneVeloTrackLine.cuh"

  // Explicit instantiation of the line
  INSTANTIATE_LINE(example_one_velo_track_line::example_one_velo_track_line_t, example_one_velo_track_line::Parameters)

  // Offset function
  __device__ unsigned example_one_velo_track_line::example_one_velo_track_line_t::offset(const Parameters& parameters,
      const unsigned event_number)
  {
    return parameters.dev_track_offsets[event_number];
  }

  //Get decision size function
  unsigned example_one_velo_track_line::example_one_velo_track_line_t::get_decisions_size(ArgumentReferences<Parameters>& arguments)
  {
    return first<typename Parameters::host_number_of_reconstructed_velo_tracks_t>(arguments);
  }

  // Get input function
  __device__ std::tuple<const unsigned> example_one_velo_track_line::example_one_velo_track_line_t::get_input(const Parameters& parameters,
      const unsigned event_number, const unsigned i)
  {
    // Get the number of events
    const uint number_of_events = parameters.dev_number_of_events[0];

    // Create the velo tracks
    Velo::Consolidated::Tracks const velo_tracks {
      parameters.dev_track_offsets,
      parameters.dev_velo_track_hit_number,
      event_number,
      number_of_events};

    // Get the ith velo track
   const unsigned track_index = i + velo_tracks.tracks_offset(event_number);

    return std::forward_as_tuple(parameters.dev_velo_track_hit_number[track_index]);
  }


  // Selection function
  __device__ bool example_one_velo_track_line::example_one_velo_track_line_t::select(const Parameters& parameters,
      std::tuple<const unsigned> input)
  {
    // Get number of hits for current velo track
    const auto& velo_track_hit_number = std::get<0>(input);

    // Check if velo track satisfies requirement
    const bool decision = ( velo_track_hit_number > parameters.minNHits);

    return decision;
  }

It is important that the return type of `get_input` is the same as the input type of `select`.


Adding your selection to the Allen sequence
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
After creating the selection source code, the selection can either be added to
an existing sequence or a new sequence is generated. Selections are added to the
Allen sequence similarly as algorithms, described in :ref:`configure_sequence`,
using the python functions defined in `AllenConf
<https://gitlab.cern.ch/lhcb/Allen/-/tree/master/configuration/python/AllenConf>`_.
Let us first look at the default sequence definition in `hlt1_pp_default.py
<https://gitlab.cern.ch/lhcb/Allen/-/tree/master/configuration/python/AllenConf>`_

.. code-block:: python

  from AllenConf.HLT1 import setup_hlt1_node
  from AllenCore.event_list_utils import generate

  hlt1_node = setup_hlt1_node()
  generate(hlt1_node)

The CompositeNode containing the default HLT1 selections `setup_hlt1_node` is defined in `HLT1.py <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/configuration/python/AllenConf/HLT1.py>`_ and contains the following code:

.. code-block:: python

  reconstructed_objects = hlt1_reconstruction()

  with line_maker.bind(enableGEC=EnableGEC):
        physics_lines = default_physics_lines(
            reconstructed_objects["velo_tracks"],
            reconstructed_objects["forward_tracks"],
            reconstructed_objects["long_track_particles"],
            reconstructed_objects["secondary_vertices"],
            reconstructed_objects["calo_matching_objects"])

  with line_maker.bind(prefilter=gec):
      monitoring_lines += alignment_monitoring_lines(
          reconstructed_objects["velo_tracks"],
          reconstructed_objects["forward_tracks"],
          reconstructed_objects["long_track_particles"],
          reconstructed_objects["velo_states"])

  # list of line algorithms, required for the gather selection and DecReport algorithms
  line_algorithms = [tup[0] for tup in physics_lines
                      ] + [tup[0] for tup in monitoring_lines]
  # lost of line nodes, required to set up the CompositeNode
  line_nodes = [tup[1] for tup in physics_lines
                ] + [tup[1] for tup in monitoring_lines]

  lines = CompositeNode(
      "SetupAllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

  gather_selections_node = CompositeNode(
      "RunAllLines",
      [lines, make_gather_selections(lines=line_algorithms)],
      NodeLogic.NONLAZY_AND,
      force_order=True)

  hlt1_node = CompositeNode(
      "Allen", [
          gather_selections_node,
          make_global_decision(lines=line_algorithms),
          *make_sel_report_writer(
              lines=line_algorithms,
              forward_tracks=reconstructed_objects["long_track_particles"],
              secondary_vertices=reconstructed_objects["secondary_vertices"])
          ["algorithms"],
      ],
      NodeLogic.NONLAZY_AND,
      force_order=True)

The default HLT1 reconstruction algorithms are called with `hlt1_reconstruction() <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/configuration/python/AllenConf/hlt1_reconstruction.py>`_. Their output is passed to the selection algorithms as required. The functions `default_physics_lines` and `default_monitoring_lines` define the default HLT1 selections. Each returns a list of tuples of `[algorithm, node]`. The list of nodes is passed as input to make the CompositeNode defining the HLT1 selections, while the list of algorithms is required as input for the DecReport algorithm.

Let us take a closer look at one example, i.e. how the Hlt1DiMuonLowMass line is defined within `default_physics_lines <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/configuration/python/AllenConf/HLT1.py>`_.

.. code-block:: python

  lines.append(
          line_maker(
              "Hlt1DiMuonLowMass",
              make_di_muon_mass_line(
                  forward_tracks,
                  secondary_vertices,
                  name="Hlt1DiMuonLowMass",
                  pre_scaler_hash_string="di_muon_low_mass_line_pre",
                  post_scaler_hash_string="di_muon_low_mass_line_post",
                  minHighMassTrackPt="500.",
                  minHighMassTrackP="3000.",
                  minMass="0.",
                  maxDoca="0.2",
                  maxVertexChi2="25.",
                  minIPChi2="4."),
                  enableGEC=True))

The `line_maker <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/configuration/python/AllenConf/HLT1.py>`_ function is called to set the line name, the line algorithm with its required inputs and to specify whether or not the prefilter of the global event cut (GEC) should be applied. The line algorithm can be configured as described below. `line_maker` returns a tuple of `[algorithm, node]` which is appended to the list of lines.

The line algorithms are defined in the files following the same naming convention as the source files:

* `hlt1_calibration_lines.py <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/configuration/python/AllenConf/hlt1_calibration_lines.py>`_
* `hlt1_charm_lines.py <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/configuration/python/AllenConf/hlt1_charm_lines.py>`_
* `hlt1_electron_lines.py <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/configuration/python/AllenConf/hlt1_electron_lines.py>`_
* `hlt1_inclusive_hadron_lines.py <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/configuration/python/AllenConf/hlt1_inclusive_hadron_lines.py>`_
* `hlt1_monitoring_lines.py <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/configuration/python/AllenConf/hlt1_monitoring_lines.py>`_
* `hlt1_muon_lines.py <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/configuration/python/AllenConf/hlt1_muon_lines.py>`_
* `hlt1_photon_lines.py <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/configuration/python/AllenConf/hlt1_photon_lines.py>`_

The HLT1DiMuonLowMass line is defined in `hlt1_muon_lines.py` as follows:

.. _make_di_muon_mass_line:
.. code-block:: python

  def make_di_muon_mass_line(forward_tracks,
                             secondary_vertices,
                             pre_scaler_hash_string="di_muon_mass_line_pre",
                             post_scaler_hash_string="di_muon_mass_line_post",
                             minHighMassTrackPt="300.",
                             minHighMassTrackP="6000.",
                             minMass="2700.",
                             maxDoca="0.2",
                             maxVertexChi2="25.",
                             minIPChi2="0.",
                             name="Hlt1DiMuonHighMass"):
      number_of_events = initialize_number_of_events()
      odin = decode_odin()
      layout = mep_layout()

      return make_algorithm(
          di_muon_mass_line_t,
          name=name,
          host_number_of_events_t=number_of_events["host_number_of_events"],
          host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
          dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
          pre_scaler_hash_string=pre_scaler_hash_string,
          post_scaler_hash_string=post_scaler_hash_string,
          minHighMassTrackPt=minHighMassTrackPt,
          minHighMassTrackP=minHighMassTrackP,
          minMass=minMass,
          maxDoca=maxDoca,
          maxVertexChi2=maxVertexChi2,
          minIPChi2=minIPChi2)

It takes as input the objects on which the selection is based (`forward_tracks`
and `secondary_vertices`), a possible pre and post scalar hash string
(`pre_scaler_hash_string` and `post_scaler_hash_string`), configurable
parameters (`minHighMassTrackPt` etc.) and a name (`"Hlt1DiMuonHighMass"`). In
the call to `make_algorithm` the arguments of the selection (`HOST_INPUT`,
`HOST_OUTPUT` and `PROPERTY`) defined in the source code are configured. In
Allen it is common practice, to set the default values of Properties within the
source code (.cu file) and only expose those Properties to python parameters
that are actually varied in a selection definition. It is particularly useful to
specify the name of a line when calling the `make_..._line` function, if more
than one configuration of the same selection is defined.

We now have the tools to create our own CompositeNode defining a custom sequence
with one of the example algorithms defined above.

Head to `configuration/sequences` and add a new configuration file.

Example: A minimal HLT1 sequence
----------------------------------
This is a minimal HLT1 sequence including only reconstruction
algorithms and the example one track line we created above. Calling
generate using the returned sequence will produce an Allen sequence
that automatically runs the example selection.

First define the line algorithm, for example within `hlt1_inclusive_hadron_lines.py`:

.. code-block:: python

  def make_example_one_track_line(forward_tracks,
                                  long_track_particles,
                                  pre_scaler_hash_string="track_mva_line_pre",
                                  post_scaler_hash_string="track_mva_line_post",
                                  name="Hlt1OneTrackExample"):
    number_of_events = initialize_number_of_events()
    odin = decode_odin()
    layout = mep_layout()

    return make_algorithm(
        example_one_track_line_t,
        name=name,
        host_number_of_events_t=number_of_events["host_number_of_events"],
        host_number_of_reconstructed_scifi_tracks_t=forward_tracks[
          "host_number_of_reconstructed_scifi_tracks"],
        dev_particle_container_t=long_track_particles[
          "dev_multi_event_basic_particles"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string)

Second, we will create the CompositeNode for the selection (rather than using
the predefined `setup_hlt1_node`) and generate the sequence within a new
configuration file `custom_hlt1.py`:

.. code-block:: python

    from AllenConf.hlt1_inclusive_hadron_lines import make_example_one_track_line
    from AllenConf.HLT1 import line_maker
    from AllenCore.event_list_utils import generate

    # Reconstruct objects needed as input for selection lines
    reconstructed_objects = hlt1_reconstruction()
    forward_tracks = reconstructed_objects["forward_tracks"]
    long_track_particles = reconstructed_objects["long_track_particles"]

    lines = []
    lines.append(
      line_maker(
          "Hlt1OneTracExample",
          make_one_track_example_line(forward_tracks, long_track_particles),
          enableGEC=True))

    line_algorithms = [tup[0] for tup in lines]
    line_nodes = [tup[1] for tup in lines]

    lines = CompositeNode(
      "AllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

    gather_selections_node = CompositeNode(
        "RunAllLines",
        [lines, make_gather_selections(lines=line_algorithms)],
        NodeLogic.NONLAZY_AND,
        force_order=True)

    custom_hlt1_node = CompositeNode(
      "Allen", [
          gather_selections_node,
          make_global_decision(lines=line_algorithms),
          *make_sel_report_writer(
              lines=line_algorithms,
              long_track_particles=reconstructed_objects["long_track_particles"],
              secondary_vertices=reconstructed_objects["secondary_vertices"])
          ["algorithms"],
      ],
      NodeLogic.NONLAZY_AND,
      force_order=True)

    generate(custom_hlt1_node)

The `lines` CompositeNode gathers all lines. In our case this is only one, but the addition of more lines is straight-forward by appending more entries to `lines` with more calls to the `line_maker`.
The `custom_hlt1_node` combines the lines with the DecReport algorithm to setup the full HLT1.

Notice that all the values of the properties have to be given in a string even if the type of the property is an `int` or a `float`.
Now, you should be able to build and run the newly generated `custom_hlt1`.

Monitoring Lines with ROOT
------------------------------
Lines can be monitored simply by adding a monitor function which fills outputs which are then written out to a tree using the ROOTService.

In addition, your selection algorithm should contain an additional property::

  Property<bool> m_enable_monitoring {this, "enable_monitoring", false, "Enable line monitoring"};

In this example we want to monitor the `Mass` and `pT` of the Secondary Vertices selected by a line meant for the decay Ks-> pi+ pi- .

First we need to add the additional `Parameters` that will carry our arrays to our `Line` header:

.. code-block:: c++

  namespace kstopipi_line {
   struct Parameters {
     (...)

     DEVICE_OUTPUT(sv_masses_t, float) sv_masses;
     DEVICE_OUTPUT(pt_t, float) pt;
    };
  };

Your selection algorithm should define an additional tuple type that contains the types of the quantities to monitor, so in this example::

.. code-block:: c++

 using monitoring_types = std::tuple<pt_t, sv_masses_t>;

The tuple type is a convenient way to store a parameter pack, which is then used internally (see `Line.cuh <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/device/selections/line_types/include/Line.cuh>`_ for details) to handle the initialisation of the containers and the transport of the arrays to the nTuple.
Two useful additional pieces of information to include in the nTuple are the event and run number.
These are automatically filled per candidate if the tuple of monitoring types includes the types runNo_t and evtNo_t, which should be declared as DEVICE_OUTPUTs of type uint64_t and unsigned for runNo and evtNo, respectively.
So in this example, we would add

.. code-block:: c++

  struct Parameters {
    (...)
    DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
    DEVICE_OUTPUT(runNo_t, unsigned) runNo;
  };

and the monitoring types becomes

.. code-block:: c++

  using monitoring_types = std::tuple<pt_t, sv_masses_t, evtNo_t, runNo_t>;

After all of the values we wish to monitor have been declared,
then we set up the `monitor` function that will be handled by the kernel in order to retrieve the information that we want to monitor:

.. code-block:: c++

   __device__ void kstopipi_line::kstopipi_line_t::monitor(
     const Parameters& parameters,
     std::tuple<const Allen::Views::Physics::CompositeParticle&> input,
     unsigned index,
     bool sel) {
       const auto& vertex = std::get<0>(input);
       if (sel) {
         parameters.sv_masses[index] = vertex.m(139.57, 139.57);
         parameters.pt[index] = vertex.pt();
       }
     }

The source files that implement these examples correspond to the `KsToPiPiLine`  and are the following:

* `Line Header <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/device/selections/lines/inclusive_hadron/include/KsToPiPiLine.cuh>`_
* `Line Implementation <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/device/selections/lines/inclusive_hadron/src/KsToPiPiLine.cu>`_

Preparing your line for rate monitoring
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
The HLT1 bandwidth (BW) division is a procedure performed offline to optimise the trigger configuration at the HLT1 level to maximise trigger efficiency whilst allowing for the broad range of LHCb physics with respect to the available bandwidth.
This is performed by the BW team and is based on the output of the HLT1 lines, which are monitored in terms of their rate in unbiased LHCb data and efficiency in relevant MC samples.

At the bare minimum every HLT1 line must be capable of having its tupling activated such that the resulting tuple contains an entry for the line with the event and run numbers of the events that passed that line.
This allows the BW team to check both the inclusive and exclusive rates of the line which is necessary even if the line is not tuned in the division.

This is achieved by editing your line algorithm, e.g. a function in `hlt1_calibration_lines.py <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/configuration/python/AllenConf/hlt1_calibration_lines.py>`_, such that the function can propagate an input `enable_tupling` to the line constructor.
Taking the HLT1DiMuonLowMass line as an example, compared to above, we add the `enable_tupling` argument:

.. code-block:: python
  
  def make_di_muon_mass_line(forward_tracks,
                            secondary_vertices,
                            pre_scaler_hash_string="di_muon_mass_line_pre",
                            post_scaler_hash_string="di_muon_mass_line_post",
                            minHighMassTrackPt="300.",
                            minHighMassTrackP="6000.",
                            minMass="2700.",
                            maxDoca="0.2",
                            maxVertexChi2="25.",
                            minIPChi2="0.",
                            name="Hlt1DiMuonHighMass",
                            enable_tupling=False):
      number_of_events = initialize_number_of_events()
      odin = decode_odin()
      layout = mep_layout()

      return make_algorithm(
          di_muon_mass_line_t,
          name=name,
          host_number_of_events_t=number_of_events["host_number_of_events"],
          host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
          dev_particle_container_t=secondary_vertices[
            "dev_multi_event_composites"],
          pre_scaler_hash_string=pre_scaler_hash_string,
          post_scaler_hash_string=post_scaler_hash_string,
          minHighMassTrackPt=minHighMassTrackPt,
          minHighMassTrackP=minHighMassTrackP,
          minMass=minMass,
          maxDoca=maxDoca,
          maxVertexChi2=maxVertexChi2,
          minIPChi2=minIPChi2,
          enable_tupling=enable_tupling)

This should then also be propagated to where it is called in `default_physics_lines <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/configuration/python/AllenConf/HLT1.py>`_ :

.. code-block:: python

  lines.append(
          line_maker(
              "Hlt1DiMuonLowMass",
              make_di_muon_mass_line(
                  forward_tracks,
                  secondary_vertices,
                  name="Hlt1DiMuonLowMass",
                  pre_scaler_hash_string="di_muon_low_mass_line_pre",
                  post_scaler_hash_string="di_muon_low_mass_line_post",
                  minHighMassTrackPt="500.",
                  minHighMassTrackP="3000.",
                  minMass="0.",
                  maxDoca="0.2",
                  maxVertexChi2="25.",
                  minIPChi2="4.",
                  enable_tupling=enable_tupling),
              enableGEC=True))

where the value of the `enable_tupling` argument is inherited from the function in which this line is called. Do not hard code it to either `False` or `True`.

This will do nothing unless the cuda code of the line is also modified to add a function to fill the tuple.

In the `.cuh` file for the line, the `struct Parameters` should be modified to include the following:

.. code-block:: c++

  DEVICE_OUTPUT(evtNo_t, uint64_t) evtNo;
  DEVICE_OUTPUT(runNo_t, unsigned) runNo;

and to the namespace of the line, add a `fill_tuples` function and the monitoring types:

.. code-block:: c++
  
  __device__ bool z_range_materialvertex_seed_line::z_range_materialvertex_seed_line::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::BasicParticle> input,
  unsigned index,
  bool sel)
  {
  return sel;
  }

  using monitoring_types = std::tuple<evtNo_t, runNo_t>;

The `.cu` file then needs the code for the function:

.. code-block:: c++

  __device__ bool di_muon_mass_line::di_muon_mass_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::BasicParticle> input,
  unsigned index,
  bool sel)
  {
  return sel;
  }

This now means that if a sequence sets `enableTupling=True` in its call to `hlt1_setup_node`, a tuple will be filled with the event and run numbers of the events that passed the line which can be used by the HLT1 BW division to check the exclusive rate of the line.

Preparing your line for HLT1 BW division tuning
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
The previous instructions aren't quite enough to facilitate the tuning of a line in the BW division. We must now enable the line to read in thresholds from the division, and also provide branches of the threshold variables in the tuples.
Thresholds are cut values for parameters of interest that are varied in the tuning process of the division to find the optimal trigger configuration that maximises signal efficiency while keeping the rate within the available bandwidth.
Taking again  the HLT1DiMuonLowMass line as an example, we must modify the line construction in `HLT1.py <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/configuration/python/AllenConf/HLT1.py>`_ to include a thresholds:

.. code-block:: python

  lines.append(
          line_maker(
              "Hlt1DiMuonLowMass",
              make_di_muon_mass_line(
                  forward_tracks,
                  secondary_vertices,
                  name="Hlt1DiMuonLowMass",
                  pre_scaler_hash_string="di_muon_low_mass_line_pre",
                  post_scaler_hash_string="di_muon_low_mass_line_post",
                  minHighMassTrackPt=thresholds.minPt_DiMuonLowMass,
                  minHighMassTrackP="3000.",
                  minMass="0.",
                  maxDoca="0.2",
                  maxVertexChi2="25.",
                  minIPChi2="4.",
                  enable_tupling=enable_tupling),
              enableGEC=True))

and now we must make sure that threshold exists in the `thresholds` object, which is defined in `thresholds.py <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/configuration/python/AllenConf/thresholds/thresholds.py>`_.
To the  `Thresholds` class, we add the following line:

.. code-block:: python

  minPt_DiMuonLowMass: float = 0.0

Where clearly the default value is set to 0.0 such that by default no cut is applied. Depending on what parameter is being tuned this will need to be adapated, e.g. a maximum pT cut would need to be set to or beyond the maximum of your expected range. This now means that any threshold file can set a value for this parameter to be cut on in HLT1.

Finally, we must add the parameter to the tuple that is filled in the line. In the `.cuh` file for the line, we add the following to the `Parameters` struct:

.. code-block:: c++

  DEVICE_OUTPUT(minHighMassTrackPt_t, float) minHighMassTrackPt;

To the private members add 

.. code-block:: c++
  
  Allen::Property<float> m_minHighMassTrackPt {this,"minHighMassTrackPt",300.f / Allen::Units::MeV,"minHighMassTrackPt description"};

And finally in the `.cu` file, we modify the `fill_tuples` function:

.. code-block:: c++

  __device__ bool di_muon_mass_line::di_muon_mass_line_t::fill_tuples(
    const Parameters& parameters,
    const DeviceProperties&,
    std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
    unsigned index,
    bool sel)
  {
    if (sel) {
      const auto particle = std::get<0>(input);
      parameters.pt[index] = particle.minpt();
    }
    return sel;
  }

Guidelines for HLT1 line merge requests (MRs)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
When creating a merge request for a new HLT1 line, please follow these guidelines. This ensures that the line can be easily integrated into the existing HLT1 framework and is ready for monitoring and tuning.

- Follow the above examples to create a new line algorithm, ensuring that it can be incorporated into the BW division, whether it needs tuning or not.
- Test the line and determine an expected rate in unbiased data. This will help us to decide if a line needs tuning and prepare our planned work accordingly.
- If the line is to be tuned, specify the tuning parameters and:
   * Ensure that the line can read in thresholds for these.
   * Add the necessary branches to the tuple that will be filled by the line.
   * Specify, in the MR description, the range over which we can vary the threshold and with what step size.
   * The line rate falls smoothly with tighter cuts on the parameter and reaches zero at your desired max/min threshold. Show plots in the MR description to illustrate this.
- If the line is to be tuned specify the MC sample to be used for the tuning. The current pool of available MC can be found in `/eos/lhcb/wg/rta/WP3/bandwidth_division/Beam6800GeV-expected-2025-MagDown-Nu7.6/``.
- Mark the current RTA-WP3 coordinator (Mika Vesterinen) and the HLT1 BW division coordinator (Aidan Wiederhold) as reviewers of the merge request as well as the appropriate RTA liaisons or equivalent for your working group or project.


ML models in selections
^^^^^^^^^^^^^^^^^^^^^^^

TwoTrackMVA
-----------

The training procedure for the TwoTrackMVA is found in `https://github.com/niklasnolte/HLT_2Track`.

The event types used for training can be seen at the end `here <https://gitlab.cern.ch/lhcb-rta/HLT_2Track/-/blob/47bd5898cb4064fabbde3da87c09ebe87d31d0c1/hlt2trk/utils/config.py>`_.

The model exported from there goes into `Allen/input/parameters/two_track_mva_model.json <https://gitlab.cern.ch/lhcb-datapkg/ParamFiles/-/blob/master/data/allen_two_track_mva_model_June22.json>`_
