.. _selections:

Writing selections
======================
This tutorial will cover adding trigger selections to Allen using the
main reconstruction sequence.

Types of selections
^^^^^^^^^^^^^^^^^^^^^^^
Selections are fully configurable algorithms in Allen. However, for ease of use, some predefined selection "types" exist that make writing new selections easier. The types of selections are discussed below.

Bear in mind that if the selection you want to write does not adhere to any of the types below, you can always create a new [custom selection](#orgd5c01de).

OneTrackLine
--------------
These trigger on single Kalman filtered long (Velo-UT-SciFi)
tracks. These are stored in the device buffer type
`dev_kf_tracks_t`. The structure of these tracks is defined in `ParKalmanDefinitions.h <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/device/kalman/ParKalman/include/ParKalmanDefinitions.cuh>`_. This includes muon ID information.

Selections can be made based on data members of `ParKalmanFilter::FittedTrack`.
    
* `ipChi2`: best PV IP chi2
* `chi2`, `ndof`: fit quality
* `is_muon`: muon ID information
    
In addition several helper member functions are available for commonly used variables: `p()`, `pt()`, `px()`, `py()`, `pz()`, `eta()`.

TwoTrackLine
---------------
These trigger on secondary vertices constructed from 2 Kalman filtered
long tracks defined in `VertexDefinitions.cuh <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/device/kalman/ParKalman/include/ParKalmanDefinitions.cuh>`_.  The input tracks
are filtered using loose requirements on IP chi2 and pT before the
secondary vertex fit. No IP chi2 requirement is imposed on dimuon and dielectron
candidates so that their reconstruction is independent of PV
reconstruction. These vertices are stored in the device buffer with type
`dev_consolidated_svs_t`.

Selections can be made based on data members of `VertexFit::TrackMVAVertex`.
    
    *   `px`, `py`, `pz`: vertex 3-momentum
    *   `x`, `y`, `z`: vertex position
    *   `chi2`: vertex fit chi2
    *   `p1`, `p2`: constituent track momenta
    *   `cos`: cos of the constituent track opening angle
    *   `vertex_ip`: Vertex IP w.r.t. matched PV
    *   `vertex_clone_sin2`: sin2 of the track opening angle
    *   `sumpt`: sum of constituent track pT
    *   `fdchi2`: vertex flight distance chi2
    *   `mdimu`: vertex mass assuming the dimuon hypothesis
    *   `mcor`: vertex corrected mass assuming dipion hypothesis
    *   `eta`: PV -> SV eta
    *   `minipchi2`: minimum IP chi2 of constituent tracks
    *   `minpt`: minimum pT of constituent tracks
    *   `ntrks16`: number of constituent tracks with a minimum IP chi2 < 16
    *   `trk1_is_muon`, `trk2_is_muon`: muon ID information for constituent tracks
    *   `is_dimuon`: `trk1_is_muon && trk2_is_muon`
    
    In addition, some helper member functions are available for commone quantities.
    
    *   `pt()`: vertex transverse momentum
    *   `m(float m1, float m2)`: vertex mass assuming mass hypotheses
        `m1` and `m2` for the constituent tracks
EventLine
-------------
These make trigger selections based on event-level information. Right
now this includes the ODIN raw bank. Examples are the minimum bias and lumi lines.

Custom line
--------------
A custom selection can trigger on any input data, and can either be based on event-level information, or on more specific information.

Adding a new selection
^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Choosing the right directory
--------------------------------
HLT1 selection lines live in the directory  `device/selections/lines <https://gitlab.cern.ch/lhcb/Allen/-/tree/master/device/selections/lines>`_ and are grouped into directories based on the selection purpose. Currently, the following subdirectories exist:

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
----------------------
Selections are `SelectionAlgorithm`s, that must in addition inherit from a line type.
Like with any other `Algorithm`, a `SelectionAlgorithm` can have inputs,
outputs and properties. However, certain inputs and outputs are assumed and must be defined:

(Total) number of events::

   HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events;

Event list to which the selection is applied::

  MASK_INPUT(dev_event_list_t);

ODIN raw inputs. Needed for pre-scalers::

  DEVICE_INPUT(dev_odin_raw_input_t, char), dev_odin_raw_input;

ODIN raw input offsets. Needed for pre-scalers::

  DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned), dev_odin_raw_input_offsets;

MEP layout. Needed to properly read ODIN input::

  DEVICE_INPUT(dev_mep_layout_t, unsigned), dev_mep_layout;

Results of the selection::

  DEVICE_OUTPUT(dev_decisions_t, bool), dev_decisions;

Offsets to each event decision::

  DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned), dev_decisions_offsets;

Post-scaler factor, such that an upcoming algorithm (usually `gather_selections_t`) can do the post-scaling::

  HOST_OUTPUT(host_post_scaler_t, float), host_post_scaler;

Hash resulting from applying the hash function to the property "post_scaler_hash_string". Needed such that an upcoming algorithm can do the post-scaling::

  HOST_OUTPUT(host_post_scaler_hash_t, uint32_t), host_post_scaler_hash;

The LHCbIDContainer type selected by the line (`track`, `sv`, or `none`)::

  HOST_OUTPUT(host_lhcbid_container_t, uint8_t) host_lhcbid_container;

Pre-scaling factor::

  PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float), pre_scaler;

Post-scaling factor::

  PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float), post_scaler;

Pre-scaler hash string. (Must not be empty)::

  PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string) pre_scaler_hash_string;

Post-scaler hash string. (Must not be empty)::

  PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string), post_scaler_hash_string;


In order to define a selection algorithm, one must define a struct as follows:

.. code-block:: c++

    struct "name_of_algorithm" : public SelectionAlgorithm, Parameters, "line_type"<"name_of_algorithm", Parameters>

In the above, `"name_of_algorithm"` is the name of the algorithm, and `"line_type"` can be either `Line` for a completely customizable line, or any of the predefined line types (such as `OneTrackLine`, `TwoTrackLine`, `ODINLine`, etc.). Please note that `"name_of_algorithm"` appears twice in the selection algorithm definition.

A `SelectionAlgorithm` can contain the following:

.. code-block:: c++

   using iteration_t = LineIteration::event_iteration_tag;

 Used if each selection is to be applied exactly once per event (eg. a lumi line).

.. code-block:: c++

   static unsigned get_decisions_size(ArgumentReferences<Parameters>& arguments) const { ... }

A function that returns the size of the decisions container.

.. code-block:: c++

   __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number) const { ... }

A function that returns the `event_number`th offset of the decisions container.

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
----------------------
As an example, we'll create a line that triggers on highly displaced,
high-pT single long tracks. It will be of type `OneTrackLine`. We will first create the
header.
        
.. code-block:: c++

  #pragma once

  #include "AlgorithmTypes.cuh"
  #include "OneTrackLine.cuh"

  namespace example_one_track_line {
    struct Parameters {
      // Commonly required inputs, outputs and properties
      HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
      MASK_INPUT(dev_event_list_t);
      DEVICE_INPUT(dev_odin_raw_input_t, char) dev_odin_raw_input;
      DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned) dev_odin_raw_input_offsets;
      DEVICE_INPUT(dev_mep_layout_t, unsigned) dev_mep_layout;
      DEVICE_OUTPUT(dev_decisions_t, bool) dev_decisions;
      DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned) dev_decisions_offsets;
      HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
      HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
      HOST_OUTPUT(host_lhcbid_container_t, uint8_t) host_lhcbid_container;
      PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
      PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
      PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string)
       pre_scaler_hash_string;
      PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string)
       post_scaler_hash_string;
      // Line-specific inputs and properties
      HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
      DEVICE_INPUT(dev_tracks_t, ParKalmanFilter::FittedTrack) dev_tracks;
      DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
      PROPERTY(minPt_t, "minPt", "minPt description", float) minPt;
      PROPERTY(minIPChi2_t, "minIPChi2", "minIPChi2 description", float) minIPChi2;
    };

    // SelectionAlgorithm definition
    struct example_one_track_line_t : public SelectionAlgorithm, Parameters, OneTrackLine<example_one_track_line_t, Parameters> {
      // Selection function.
      __device__ static bool select(const Parameters& parameters, std::tuple<const ParKalmanFilter::FittedTrack&> input);

    private:
      // Commonly required properties
      Property<pre_scaler_t> m_pre_scaler {this, 1.f};
      Property<post_scaler_t> m_post_scaler {this, 1.f};
      Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
      Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
      // Line-specific properties
      Property<minPt_t> m_minPt {this, 10000.0f * Gaudi::Units::MeV};
      Property<minIPChi2_t> m_minIPChi2 {this, 25.0f};
    };
  } // namespace example_one_track_line

And the then the source:

.. code-block:: c++

  #include "ExampleOneTrackLine.cuh"

  // Explicit instantiation of the line
  INSTANTIATE_LINE(example_one_track_line::example_one_track_line_t, example_one_track_line::Parameters)

  __device__ bool example_one_track_line::example_one_track_line_t::select(
    const Parameters& parameters,
    std::tuple<const ParKalmanFilter::FittedTrack&> input) 
  {
    const auto& track = std::get<0>(input);
    const bool decision = track.pt() > parameters.minPt && track.ipChi2 > parameters.minIPChi2;
    return decision;
  }

Note that since the type of this line was the preexisting (`OneTrackLine`), it was not
necessary to define any function other than `select`.

TwoTrackLine example
-----------------------
Here we'll create an example of a 2-long-track line that selects displaced
secondary vertices with no postscale. This line inherits from `TwoTrackLine`. We'll create a header with the following contents:
    
.. code-block:: c++

  #pragma once

  #include "AlgorithmTypes.cuh"
  #include "TwoTrackLine.cuh"

  namespace example_two_track_line {
    struct Parameters {
      // Commonly required inputs, outputs and properties
      HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
      MASK_INPUT(dev_event_list_t);
      DEVICE_INPUT(dev_odin_raw_input_t, char) dev_odin_raw_input;
      DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned) dev_odin_raw_input_offsets;
      DEVICE_INPUT(dev_mep_layout_t, unsigned) dev_mep_layout;
      DEVICE_OUTPUT(dev_decisions_t, bool) dev_decisions;
      DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned) dev_decisions_offsets;
      HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
      HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
      HOST_OUTPUT(host_lhcbid_container_t, uint8_t) host_lhcbid_container;
      PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
      PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
      PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string)
       pre_scaler_hash_string;
      PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string)
       post_scaler_hash_string;
      // Line-specific inputs and properties
      HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
      DEVICE_INPUT(dev_svs_t, VertexFit::TrackMVAVertex) dev_svs;
      DEVICE_INPUT(dev_sv_offsets_t, unsigned) dev_sv_offsets;
      PROPERTY(minComboPt_t, "minComboPt", "minComboPt description", float) minComboPt;
      PROPERTY(minTrackPt_t, "minTrackPt", "minTrackPt description", float) minTrackPt;
      PROPERTY(minTrackIPChi2_t, "minTrackIPChi2", "minTrackIPChi2 description", float) minTrackIPChi2;
    };

    // SelectionAlgorithm definition
    struct example_two_track_line_t : public SelectionAlgorithm, Parameters, TwoTrackLine<example_two_track_line_t, Parameters> {
      // Selection function.
      __device__ static bool select(const Parameters&, std::tuple<const VertexFit::TrackMVAVertex&>);

    private:
      // Commonly required properties
      Property<pre_scaler_t> m_pre_scaler {this, 1.f};
      Property<post_scaler_t> m_post_scaler {this, 1.f};
      Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
      Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
      // Line-specific properties
      Property<minComboPt_t> m_minComboPt {this, 2000.0f * Gaudi::Units::MeV};
      Property<minTrackPt_t> m_minTrackPt {this, 500.0f * Gaudi::Units::MeV};
      Property<minTrackIPChi2_t> m_minTrackIPChi2 {this, 25.0f};
    };

  } // namespace example_two_track_line

And a source with the following:

.. code-block:: c++

  #include "ExampleTwoTrackLine.cuh"

  INSTANTIATE_LINE(example_two_track_line::example_two_track_line_t, example_two_track_line::Parameters)

  __device__ bool example_two_track_line::example_two_track_line_t::select(
    const Parameters& parameters,
    std::tuple<const VertexFit::TrackMVAVertex&> input)
  {
    const auto& vertex = std::get<0>(input);

    // Make sure the vertex fit succeeded.
    if (vertex.chi2 < 0) {
      return false;
    }

    const bool decision = vertex.pt() > parameters.minComboPt && 
      vertex.minpt > parameters.minTrackPt &&
      vertex.minipchi2 > parameters.minTrackIPChi2;
    return decision;
  }

EventLine example
--------------------
Now we'll define a line that selects events with at least 1 reconstructed VELO track. This line runs once per event, so it inherits from `EventLine`.
This time, we will need to define not only the `select` function, but also the `get_input` function, as we need custom data to feed into our line (the number of tracks in an event).

The header `monitoring/include/VeloMicroBiasLine.cuh <https://gitlab.cern.ch/lhcb/Allen/-/tree/master/device/selections/lines>`_ is as follows:

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
      DEVICE_INPUT(dev_odin_raw_input_t, char) dev_odin_raw_input;
      DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned) dev_odin_raw_input_offsets;
      DEVICE_INPUT(dev_mep_layout_t, unsigned) dev_mep_layout;
      DEVICE_OUTPUT(dev_decisions_t, bool) dev_decisions;
      DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned) dev_decisions_offsets;
      HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
      HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
      HOST_OUTPUT(host_lhcbid_container_t, uint8_t) host_lhcbid_container;
      PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
      PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
      PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string)
       pre_scaler_hash_string;
      PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string)
       post_scaler_hash_string;
      // Line-specific inputs and properties
      DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
      DEVICE_INPUT(dev_offsets_velo_tracks_t, unsigned) dev_offsets_velo_tracks;
      DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned) dev_offsets_velo_track_hit_number;
      PROPERTY(min_velo_tracks_t, "min_velo_tracks", "Minimum number of VELO tracks", unsigned) min_velo_tracks;
    };

    struct velo_micro_bias_line_t : public SelectionAlgorithm, Parameters, EventLine<velo_micro_bias_line_t, Parameters> {
      __device__ static std::tuple<const unsigned>
      get_input(const Parameters& parameters, const unsigned event_number);

      __device__ static bool select(const Parameters& parameters, std::tuple<const unsigned> input);

    private:
      // Commonly required properties
      Property<pre_scaler_t> m_pre_scaler {this, 1.f};
      Property<post_scaler_t> m_post_scaler {this, 1.f};
      Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
      Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
      // Line-specific properties
      Property<min_velo_tracks_t> m_min_velo_tracks {this, 1};
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
--------------------
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
      HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
      MASK_INPUT(dev_event_list_t);
      DEVICE_INPUT(dev_odin_raw_input_t, char) dev_odin_raw_input;
      DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned) dev_odin_raw_input_offsets;
      DEVICE_INPUT(dev_mep_layout_t, unsigned) dev_mep_layout;
      DEVICE_OUTPUT(dev_decisions_t, bool) dev_decisions;
      DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned) dev_decisions_offsets;
      HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
      HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
      HOST_OUTPUT(host_lhcbid_container_t, uint8_t) host_lhcbid_container;
      PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
      PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
      PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string) pre_scaler_hash_string;
      PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string) post_scaler_hash_string;
      // Line-specific inputs and properties
      DEVICE_INPUT(dev_track_offsets_t, unsigned) dev_track_offsets;
      DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
      DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned) dev_velo_track_hit_number;
      PROPERTY(minNHits_t, "minNHits", "min number of hits of velo track", unsigned) minNHits;
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
      // Commonly required properties
      Property<pre_scaler_t> m_pre_scaler {this, 1.f};
      Property<post_scaler_t> m_post_scaler {this, 1.f};
      Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
      Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
      // Line-specific properties
      Property<minNHits_t> m_minNHits {this, 0};
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

LHCbIDContainer
^^^^^^^^^^^^^^^^^^^^
Each line must have a public data member `lhcbid_container` specifying the type of LHCbIDContainer the line selects. This tells the SelReport writer how to construct the SelReport for each line. Currently this can be a track, a secondary vertex, or none. For predefined line types, this has already been defined:

* `OneTrackLine`: `constexpr static auto lhcbid_container = LHCbIDContainer::track;`
* `TwoTrackLine`: `constexpr static auto lhcbid_container = LHCbIDContainer::sv;`
* `EventLine`: `constexpr static auto lhcbid_container = LHCbIDContainer::none;`

Adding your selection to the Allen sequence
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
After creating the selection source code, the selection can either be added to an existing sequence or a new sequence is generated.
Selections are added to the Allen sequence similarly as
algorithms, described in :ref:`configure_sequence`, using the python functions defined in `AllenConf <https://gitlab.cern.ch/lhcb/Allen/-/tree/master/configuration/python/AllenConf>`_.  
Let us first look at the default sequence definition in `hlt1_pp_default.py <https://gitlab.cern.ch/lhcb/Allen/-/tree/master/configuration/python/AllenConf>`_

.. code-block:: python

  from AllenConf.HLT1 import setup_hlt1_node
  from AllenCore.event_list_utils import generate

  hlt1_node = setup_hlt1_node()
  generate(hlt1_node)

The CompositeNode containing the default HLT1 selections `setup_hlt1_node` is defined in `HLT1.py <https://gitlab.cern.ch/lhcb/Allen/-/tree/master/configuration/python/AllenConf>`_ and contains the following code:

.. code-block:: python

  reconstructed_objects = hlt1_reconstruction()

  with line_maker.bind(enableGEC=EnableGEC):
          physics_lines = default_physics_lines(
              reconstructed_objects["velo_tracks"],
              reconstructed_objects["forward_tracks"],
              reconstructed_objects["kalman_velo_only"],
              reconstructed_objects["secondary_vertices"])

      monitoring_lines = default_monitoring_lines(
          reconstructed_objects["velo_tracks"])

      # list of line algorithms, required for the gather selection and DecReport algorithms
      line_algorithms = [tup[0] for tup in physics_lines
                         ] + [tup[0] for tup in monitoring_lines]
      # lost of line nodes, required to set up the CompositeNode
      line_nodes = [tup[1] for tup in physics_lines
                    ] + [tup[1] for tup in monitoring_lines]

      lines = CompositeNode(
          "AllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

      hlt1_node = CompositeNode(
          "Allen", [lines, make_dec_reporter(lines=line_algorithms)],
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
          dev_odin_raw_input_t=odin["dev_odin_raw_input"],
          dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
          dev_mep_layout_t=layout["dev_mep_layout"],
          host_number_of_svs_t=secondary_vertices["host_number_of_svs"],
          dev_svs_t=secondary_vertices["dev_consolidated_svs"],
          dev_sv_offsets_t=secondary_vertices["dev_sv_offsets"],
          pre_scaler_hash_string=pre_scaler_hash_string,
          post_scaler_hash_string=post_scaler_hash_string,
          minHighMassTrackPt=minHighMassTrackPt,
          minHighMassTrackP=minHighMassTrackP,
          minMass=minMass,
          maxDoca=maxDoca,
          maxVertexChi2=maxVertexChi2,
          minIPChi2=minIPChi2)

It takes as input the objects on which the selection is based (`forward_tracks` and `secondary_vertices`), a possible pre and post scalar hash string (`pre_scaler_hash_string` and `post_scaler_hash_string`), configurable parameters (`minHighMassTrackPt` etc.) and a name (`"Hlt1DiMuonHighMass"`). In the call to `make_algorithm` the arguments of the selection (`HOST_INPUT`, `HOST_OUTPUT` and `PROPERTY`) defined in the source code are configured. 
In Allen it is common practice, to set the default values of Properties within the source code (.cu file) and only expose those Properties to python parameters that are actually varied in a selection definition. It is particularly useful to specify the name of a line when calling the `make_..._line` function, if more than one configuration of the same selection is defined.

We now have the tools to create our own CompositeNode defining a custom sequence with one of the example algorithms defined above.

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
                        kalman_velo_only,
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
        dev_tracks_t=kalman_velo_only["dev_kf_tracks"],
        dev_track_offsets_t=forward_tracks["dev_offsets_forward_tracks"],
        dev_odin_raw_input_t=odin["dev_odin_raw_input"],
        dev_odin_raw_input_offsets_t=odin["dev_odin_raw_input_offsets"],
        dev_mep_layout_t=layout["dev_mep_layout"],
        pre_scaler_hash_string=pre_scaler_hash_string,
        post_scaler_hash_string=post_scaler_hash_string)

Second, we will create the CompositeNode for the selection (rather than using the predefined `setup_hlt1_node`) and generate the sequence within a new configuration file `custom_hlt1.py`:

.. code-block:: python

    from AllenConf.hlt1_inclusive_hadron_lines import make_example_one_track_line
    from AllenConf.HLT1 import line_maker
    from AllenCore.event_list_utils import generate

    # Reconstruct objects needed as input for selection lines
    reconstructed_objects = hlt1_reconstruction()

    lines = []
    lines.append(
      line_maker(
          "Hlt1OneTracExample",
          make_one_track_example_line(forward_tracks, kalman_velo_only),
          enableGEC=True))

    line_algorithms = [tup[0] for tup in lines]
    line_nodes = [tup[1] for tup in lines]

    lines = CompositeNode(
      "AllLines", line_nodes, NodeLogic.NONLAZY_OR, force_order=False)

    custom_hlt1_node = CompositeNode(
      "Allen", [
          lines,
          make_sel_report_writer(
              lines=line_algorithms,
              forward_tracks=reconstructed_objects["forward_tracks"],
              secondary_vertices=reconstructed_objects["secondary_vertices"])
          ["dev_sel_reports"].producer,
          make_global_decision(lines=line_algorithms)
      ],
      NodeLogic.NONLAZY_AND,
      force_order=True)

    generate(custom_hlt1_node)

The `lines` CompositeNode gathers all lines. In our case this is only one, but the addition of more lines is straight-forward by appending more entries to `lines` with more calls to the `line_maker`. 
The `custom_hlt1_node` combines the lines with the DecReport algorithm to setup the full HLT1. 
  
Notice that all the values of the properties have to be given in a string even if the type of the property is an `int` or a `float`.
Now, you should be able to build and run the newly generated `custom_hlt1`.


ML models in selections
^^^^^^^^^^^^^^^^^^^^^^^^^^^

TwoTrackMVA
----------------

The training procedure for the TwoTrackMVA is found in `https://github.com/niklasnolte/HLT_2Track`.

The event types used for training can be seen in `here <https://github.com/niklasnolte/HLT_2Track/blob/main/hlt2trk/utils/config.py#L384>`_.

The model exported from there goes into `Allen/input/parameters/two_track_mva_model.json <https://gitlab.cern.ch/lhcb/Allen/-/blob/master/input/parameters/two_track_mva_model.json>`_
    
