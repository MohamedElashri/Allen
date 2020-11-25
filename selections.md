# Table of Contents

1.  [Types of selections](#types-of-selections)
    1.  [OneTrackLine](#onetrackline)
    2.  [TwoTrackLine](#twotrackline)
    3.  [EventLine](#eventline)
    4.  [Custom selections](#custom-selections)
2.  [Adding a new selection](#adding-a-new-selection)
    1.  [Creating a selection](#creating-a-selection)
        1.  [OneTrackLine example](#onetrackline-example)
        2.  [TwoTrackLine example](#twotrackline-example)
        3.  [EventLine example](#eventline-example)
        4.  [CustomLine example](#customline-example)
    2.  [Adding your selection algorithm to the Allen sequence](#adding-your-selection-to-the-allen-sequence)


# Allen: Adding a new selection

This tutorial will cover adding trigger selections to Allen using the
main reconstruction sequence.

## Types of selections

Selections are fully configurable algorithms in Allen. However, for ease of use, some predefined selection "types" exist that make writing new selections easier. The types of selections are discussed below.

Bear in mind that if the selection you want to write does not adhere to any of the types below, you can always create a new [custom selection](#orgd5c01de).

### OneTrackLine

These trigger on single Kalman filtered long (Velo-UT-SciFi)
tracks. These are stored in the device buffer type
`dev_kf_tracks_t`. The structure of these tracks is defined in
`device/kalman/ParKalman/include/ParKalmanDefinitions.cuh`. This
includes muon ID information.

1.  Available selection criteria

    Selections can be made based on data members of `ParKalmanFilter::FittedTrack`.
    
    -   `ipChi2`: best PV IP chi2
    -   `chi2`, `ndof`: fit quality
    -   `is_muon`: muon ID information
    
    In addition several helper member functions are available for common
    quantities.
    
    -   `p()`, `pt()`, `px()`, `py()`, `pz()`, `eta()`: self-explanatory
        momentum information


### TwoTrackLine

These trigger on secondary vertices constructed from 2 Kalman filtered
long tracks defined in
`device/vertex_fit/common/include/VertexDefinitions.cuh`. These tracks
are filtered using loose requirements on IP chi2 and pT before the
secondary vertex fit. No IP chi2 requirement is imposed on dimuon
candidates so that their reconstruction is independent of PV
reconstruction. These vertices in the device buffer with type
`dev_consolidated_svs_t`.

1.  Available selection criteria

    Selections can be made based on data members of `VertexFit::TrackMVAVertex`.
    
    -   `px`, `py`, `pz`: vertex 3-momentum
    -   `x`, `y`, `z`: vertex position
    -   `chi2`: vertex fit chi2
    -   `p1`, `p2`: constituent track momenta
    -   `cos`: cos of the constituent track opening angle
    -   `vertex_ip`: Vertex IP w.r.t. matched PV
    -   `vertex_clone_sin2`: sin2 of the track opening angle
    -   `sumpt`: sum of constituent track pT
    -   `fdchi2`: vertex flight distance chi2
    -   `mdimu`: vertex mass assuming the dimuon hypothesis
    -   `mcor`: vertex corrected mass assuming dipion hypothesis
    -   `eta`: PV -> SV eta
    -   `minipchi2`: minimum IP chi2 of constituent tracks
    -   `minpt`: minimum pT of constituent tracks
    -   `ntrks16`: number of constituent tracks with a minimum IP chi2 < 16
    -   `trk1_is_muon`, `trk2_is_muon`: muon ID information for constituent tracks
    -   `is_dimuon`: `trk1_is_muon && trk2_is_muon`
    
    In addition, some helper member functions are available for commone quantities.
    
    -   `pt()`: vertex transverse momentum
    -   `m(float m1, float m2)`: vertex mass assuming mass hypotheses
        `m1` and `m2` for the constituent tracks

### EventLine

These make trigger selections based on event-level information. Right
now this includes the ODIN raw bank. This includes minimum bias and lumi lines.

### Custom line

A custom selection can trigger on any input data, and can either be based on event-level information, or on more specific information.

## Adding a new selection

### Creating a selection

Selections are `SelectionAlgorithm`s, that must in addition inherit from a line type.

Like with any other `Algorithm`, a `SelectionAlgorithm` can have inputs,
outputs and properties. However, certain inputs and outputs are assumed and must be defined:

* `(HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events)`: (Total) number of events.
* `(DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list)`: Event list that will be applied the selection.
* `(DEVICE_INPUT(dev_odin_raw_input_t, char), dev_odin_raw_input)`: ODIN raw inputs. Needed for pre-scalers.
* `(DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned), dev_odin_raw_input_offsets)`: ODIN raw input offsets. Needed for pre-scalers.
* `(DEVICE_INPUT(dev_mep_layout_t, unsigned), dev_mep_layout)`: MEP layout. Needed to properly read ODIN input.
* `(DEVICE_OUTPUT(dev_decisions_t, bool), dev_decisions)`: Will contain the results of the selection.
* `(DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned), dev_decisions_offsets)`: Will contain the offsets to each event decisions.
* `(HOST_OUTPUT(host_post_scaler_t, float), host_post_scaler)`: Will contain the post-scaler factor, such that an upcoming algorithm (usually `gather_selections_t`) can do the post-scaling.
* `(HOST_OUTPUT(host_post_scaler_hash_t, uint32_t), host_post_scaler_hash)`: Will contain the hash resulting from applying the hash function to the property "post_scaler_hash_string". Needed such that an upcoming algorithm can do the post-scaling.
* `(PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float), pre_scaler)`: Pre-scaling factor.
* `(PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float), post_scaler)`: Post-scaling factor.
* `(PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string) pre_scaler_hash_string)`: Pre-scaler hash string. Must not be empty.
* `(PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string), post_scaler_hash_string)`: Post-scaler hash string. Must not be empty.

In order to define a selection algorithm, one must define a struct as follows:

    struct "name_of_algorithm" : public SelectionAlgorithm, Parameters, "line_type"<"name_of_algorithm", Parameters>

In the above, `"name_of_algorithm"` is the name of the algorithm, and `"line_type"` can be either `Line` for a completely customizable line, or any of the predefined line types (such as `OneTrackLine`, `TwoTrackLine`, `ODINLine`, etc.). Please note that `"name_of_algorithm"` appears twice in the selection algorithm definition.

A `SelectionAlgorithm` can contain the following:

* `using iteration_t = LineIteration::event_iteration_tag;`: Used if each selection is to be applied exactly once per event (eg. a lumi line).
* `unsigned get_decisions_size(ArgumentReferences<Parameters>& arguments) const { ... }`: A function that returns the size of the decisions container.
* `__device__ unsigned offset(const Parameters& parameters, const unsigned event_number) const { ... }`: A function that returns the `event_number`th offset of the decisions container.
* ```c++
  __device__ std::tuple<"configurable_types">
  get_input(const Parameters& parameters, const unsigned event_number, const unsigned i) const {
      ...
      return std::forward_as_tuple("instances");
  }
  ```
  A function that gets the `i`th input of `event_number`, and returns it as a tuple. The `"configurable_types"` can be anything. The return statement of the function is suggested to be a `return std::forward_as_tuple()` with the `"instances"` of the desired objects. The return type of this function will be used as the input of the `select` function.
* ```c++
  __device__ bool select(
      const Parameters& parameters,
      std::tuple<"configurable_types"> input) const
  {
      ...
      return [true/false];
  }
  ```
  The function that performs the selection for a single input. The type of the input must match the `"configurable_types"` of the `get_input` function. It returns a boolean with the decision output.
* Optional: `unsigned get_block_dim_x(const ArgumentReferences<Parameters>&) const { ... }`: Defines the number of threads the selection will be performed with.

In addition, lines must be instantiated in their source file definition:

* `INSTANTIATE_LINE("name_of_algorithm", "parameters_of_algorithm")`

Below are four examples of lines.

#### OneTrackLine example

As an example, we'll create a line that triggers on highly displaced,
high-pT single long tracks. It will be of type `OneTrackLine`. We will create the
header `device/selections/lines/include/ExampleOneTrackLine.cuh`.
        
```c++
#pragma once

#include "SelectionAlgorithm.cuh"
#include "OneTrackLine.cuh"

namespace example_one_track_line {
  DEFINE_PARAMETERS(
    Parameters,
    // Commonly required inputs, outputs and properties
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_odin_raw_input_t, char), dev_odin_raw_input),
    (DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned), dev_odin_raw_input_offsets),
    (DEVICE_INPUT(dev_mep_layout_t, unsigned), dev_mep_layout),
    (DEVICE_OUTPUT(dev_decisions_t, bool), dev_decisions),
    (DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned), dev_decisions_offsets),
    (HOST_OUTPUT(host_post_scaler_t, float), host_post_scaler),
    (HOST_OUTPUT(host_post_scaler_hash_t, uint32_t), host_post_scaler_hash),
    (PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float), pre_scaler),
    (PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float), post_scaler),
    (PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string),
     pre_scaler_hash_string),
    (PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string),
     post_scaler_hash_string),
    // Line-specific inputs and properties
    (HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned), host_number_of_reconstructed_scifi_tracks),
    (DEVICE_INPUT(dev_tracks_t, ParKalmanFilter::FittedTrack), dev_tracks),
    (DEVICE_INPUT(dev_track_offsets_t, unsigned), dev_track_offsets),
    (PROPERTY(minPt_t, "minPt", "minPt description", float), minPt),
    (PROPERTY(minIPChi2_t, "minIPChi2", "minIPChi2 description", float), minIPChi2))

  // SelectionAlgorithm definition
  struct example_one_track_line_t : public SelectionAlgorithm, Parameters, OneTrackLine<example_one_track_line_t, Parameters> {
    // Selection function.
    __device__ bool select(const Parameters& parameters, std::tuple<const ParKalmanFilter::FittedTrack&> input) const;

  private:
    Property<minPt_t> m_minPt {this, 10000.0f / Gaudi::Units::GeV};
    Property<minIPChi2_t> m_minIPChi2 {this, 25.0f};
  };
} // namespace example_one_track_line
```

And the source in `device/selections/lines/src/ExampleOneTrackLine.cu`:

```c++
#include "ExampleOneTrackLine.cuh"

// Explicit instantiation of the line
INSTANTIATE_LINE(example_one_track_line::example_one_track_line_t, example_one_track_line::Parameters)

__device__ bool example_one_track_line::example_one_track_line_t::select(
  const Parameters& parameters,
  std::tuple<const ParKalmanFilter::FittedTrack&> input) const
{
  const auto& track = std::get<0>(input);
  const bool decision = track.pt() > parameters.minPt && track.ipChi2 > parameters.minIPChi2;
  return decision;
}
```

Note that since the type of this line was preexisting (`OneTrackLine`), it was not
necessary to define any function other than `select`.

#### TwoTrackLine example

Here we'll create an example of a 2-long-track line that selects displaced
secondary vertices with no postscale. This lines inherit from `TwoTrackLine`. We'll create a header in
`device/selections/lines/include/ExampleTwoTrackLine.cuh` with the following contents:
    
```c++
#pragma once

#include "SelectionAlgorithm.cuh"
#include "TwoTrackLine.cuh"

namespace example_two_track_line {
  DEFINE_PARAMETERS(
    Parameters,
    // Commonly required inputs, outputs and properties
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_odin_raw_input_t, char), dev_odin_raw_input),
    (DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned), dev_odin_raw_input_offsets),
    (DEVICE_INPUT(dev_mep_layout_t, unsigned), dev_mep_layout),
    (DEVICE_OUTPUT(dev_decisions_t, bool), dev_decisions),
    (DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned), dev_decisions_offsets),
    (HOST_OUTPUT(host_post_scaler_t, float), host_post_scaler),
    (HOST_OUTPUT(host_post_scaler_hash_t, uint32_t), host_post_scaler_hash),
    (PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float), pre_scaler),
    (PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float), post_scaler),
    (PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string),
     pre_scaler_hash_string),
    (PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string),
     post_scaler_hash_string),
    // Line-specific inputs and properties
    (HOST_INPUT(host_number_of_svs_t, unsigned), host_number_of_svs),
    (DEVICE_INPUT(dev_svs_t, VertexFit::TrackMVAVertex), dev_svs),
    (DEVICE_INPUT(dev_sv_offsets_t, unsigned), dev_sv_offsets),
    (PROPERTY(minComboPt_t, "minComboPt", "minComboPt description", float), minComboPt),
    (PROPERTY(minTrackPt_t, "minTrackPt", "minTrackPt description", float), minTrackPt),
    (PROPERTY(minTrackIPChi2_t, "minTrackIPChi2", "minTrackIPChi2 description", float), minTrackIPChi2))

  // SelectionAlgorithm definition
  struct example_two_track_line_t : public SelectionAlgorithm, Parameters, TwoTrackLine<example_two_track_line_t, Parameters> {
    // Selection function.
    __device__ bool select(const Parameters&, std::tuple<const VertexFit::TrackMVAVertex&>) const;

  private:
    Property<minComboPt_t> m_minComboPt {this, 2000.0f / Gaudi::Units::GeV};
    Property<minTrackPt_t> m_minTrackPt {this, 500.0f / Gaudi::Units::MeV};
    Property<minTrackIPChi2_t> m_minTrackIPChi2 {this, 25.0f};
  };

} // namespace example_two_track_line
```

And a source in `device/selections/lines/src/ExampleTwoTrackLine.cu` with the following:

```c++
#include "ExampleTwoTrackLine.cuh"

INSTANTIATE_LINE(example_two_track_line::example_two_track_line_t, example_two_track_line::Parameters)

__device__ bool example_two_track_line::example_two_track_line_t::select(
  const Parameters& parameters,
  std::tuple<const VertexFit::TrackMVAVertex&> input) const
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
```

#### EventLine example

Now we'll define a line that selects events with at least 1 reconstructed VELO track. This line runs once per event, so it inherits from `EventLine`.
This time, we will need to define not only the `select` function, but also the `get_input` function, as we need custom data to feed into our line (the number of tracks in an event).

The header `VeloMicroBiasLine.cuh` is as follows:

```c++
#pragma once

#include "SelectionAlgorithm.cuh"
#include "EventLine.cuh"
#include "VeloConsolidated.cuh"

namespace velo_micro_bias_line {
  DEFINE_PARAMETERS(
    Parameters,
    // Commonly required inputs, outputs and properties
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_odin_raw_input_t, char), dev_odin_raw_input),
    (DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned), dev_odin_raw_input_offsets),
    (DEVICE_INPUT(dev_mep_layout_t, unsigned), dev_mep_layout),
    (DEVICE_OUTPUT(dev_decisions_t, bool), dev_decisions),
    (DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned), dev_decisions_offsets),
    (HOST_OUTPUT(host_post_scaler_t, float), host_post_scaler),
    (HOST_OUTPUT(host_post_scaler_hash_t, uint32_t), host_post_scaler_hash),
    (PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float), pre_scaler),
    (PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float), post_scaler),
    (PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string),
     pre_scaler_hash_string),
    (PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string),
     post_scaler_hash_string),
    // Line-specific inputs and properties
    (DEVICE_INPUT(dev_number_of_events_t, unsigned), dev_number_of_events),
    (DEVICE_INPUT(dev_offsets_velo_tracks_t, unsigned), dev_offsets_velo_tracks),
    (DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned), dev_offsets_velo_track_hit_number),
    (PROPERTY(min_velo_tracks_t, "min_velo_tracks", "Minimum number of VELO tracks", unsigned), min_velo_tracks))

  struct velo_micro_bias_line_t : public SelectionAlgorithm, Parameters, EventLine<velo_micro_bias_line_t, Parameters> {
    __device__ std::tuple<const unsigned>
    get_input(const Parameters& parameters, const unsigned event_number) const;

    __device__ bool select(const Parameters& parameters, std::tuple<const unsigned> input) const;

  private:
    Property<min_velo_tracks_t> m_min_velo_tracks {this, 1};
  };
} // namespace velo_micro_bias_line
```

Note that we have added three inputs to obtain VELO track information (`dev_offsets_velo_tracks_t`, `dev_offsets_velo_track_hit_number_t` and `dev_number_of_events_t`). Finally, `get_input` is declared as well, which we will have to define in the source file. `get_input` will return a `std::tuple<const unsigned>`, which is the type of the `input` argument in `select`.

The source file looks as follows:

```c++
#include "VeloMicroBiasLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(velo_micro_bias_line::velo_micro_bias_line_t, velo_micro_bias_line::Parameters)

__device__ std::tuple<const unsigned>
velo_micro_bias_line::velo_micro_bias_line_t::get_input(const Parameters& parameters, const unsigned event_number) const
{
  Velo::Consolidated::ConstTracks velo_tracks {
    parameters.dev_offsets_velo_tracks, parameters.dev_offsets_velo_track_hit_number, event_number, parameters.dev_number_of_events[0]};
  const unsigned number_of_velo_tracks = velo_tracks.number_of_tracks(event_number);
  return std::forward_as_tuple(number_of_velo_tracks);
}

__device__ bool velo_micro_bias_line::velo_micro_bias_line_t::select(
  const Parameters& parameters,
  std::tuple<const unsigned> input) const
{
  const auto number_of_velo_tracks = std::get<0>(input);
  return number_of_velo_tracks >= parameters.min_velo_tracks;
}
```

`get_input` gets the number of VELO tracks and returns it, and `select` will select only events with VELO tracks.


#### CustomLine example

Finally, we'll define a line that runs on every velo track. Since this is a completely custom line, we need to define all the function of the line, i.e. `select`, `get_input`, `get_decisions_size` and `offset`.
In addition, we also need to add some properties to the line.

The header `ExampleOneVeloTrackLine.cuh` is as follows:

```c++
#pragma once

#include "SelectionAlgorithm.cuh"
#include "Line.cuh"
#include "VeloConsolidated.cuh"

namespace example_one_velo_track_line {
  DEFINE_PARAMETERS(
    Parameters,
    // Commonly required inputs, outputs and properties
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned), host_number_of_reconstructed_velo_tracks),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_odin_raw_input_t, char), dev_odin_raw_input),
    (DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned), dev_odin_raw_input_offsets),
    (DEVICE_INPUT(dev_mep_layout_t, unsigned), dev_mep_layout),
    (DEVICE_OUTPUT(dev_decisions_t, bool), dev_decisions),
    (DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned), dev_decisions_offsets),
    (HOST_OUTPUT(host_post_scaler_t, float), host_post_scaler),
    (HOST_OUTPUT(host_post_scaler_hash_t, uint32_t), host_post_scaler_hash),
    (PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float), pre_scaler),
    (PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float), post_scaler),
    (PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string), pre_scaler_hash_string),
    (PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string), post_scaler_hash_string),
    // Line-specific inputs and properties
    (DEVICE_INPUT(dev_track_offsets_t, unsigned), dev_track_offsets),
    (DEVICE_INPUT(dev_number_of_events_t, unsigned), dev_number_of_events),
    (DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned), dev_velo_track_hit_number),
    (PROPERTY(minNHits_t, "minNHits", "min number of hits of velo track", unsigned), minNHits))


  // SelectionAlgorithm definition
  struct example_one_velo_track_line_t : public SelectionAlgorithm, Parameters, Line<example_one_velo_track_line_t, Parameters> {

      // Offset function
      __device__ unsigned offset(const Parameters& parameters, const unsigned event_number) const;
    
      //Get decision size function
      unsigned get_decisions_size(ArgumentReferences<Parameters>& arguments) const;
    
      // Get input function
      __device__ std::tuple<const unsigned> get_input(const Parameters& parameters, const unsigned event_number, const unsigned i) const;
    
      // Selection function
      __device__ bool select(const Parameters& parameters, std::tuple<const unsigned> input) const;


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
```
    
Note that we have added some inputs and one property.

The source file looks as follows:
    
```c++
#include "ExampleOneVeloTrackLine.cuh"

// Explicit instantiation of the line
INSTANTIATE_LINE(example_one_velo_track_line::example_one_velo_track_line_t, example_one_velo_track_line::Parameters)

// Offset function
__device__ unsigned example_one_velo_track_line::example_one_velo_track_line_t::offset(const Parameters& parameters, 
    const unsigned event_number) const
{
  return parameters.dev_track_offsets[event_number];
}

//Get decision size function
unsigned example_one_velo_track_line::example_one_velo_track_line_t::get_decisions_size(ArgumentReferences<Parameters>& arguments) const
{
  return first<typename Parameters::host_number_of_reconstructed_velo_tracks_t>(arguments);
}

// Get input function
__device__ std::tuple<const unsigned> example_one_velo_track_line::example_one_velo_track_line_t::get_input(const Parameters& parameters, 
    const unsigned event_number, const unsigned i) const
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
    std::tuple<const unsigned> input) const
{
  // Get number of hits for current velo track
  const auto& velo_track_hit_number = std::get<0>(input);

  // Check if velo track satisfies requirement
  const bool decision = ( velo_track_hit_number > parameters.minNHits);

  return decision;
}
```

It is important that the return type of `get_input` is the same as the input type of `select`.


### Adding your selection to the Allen sequence

Selections are added to the Allen sequence similarly to
algorithms. After creating the selection source code, a new sequence
must be generated. Head to `configuration/sequences` and add a new
configuration file.

1.  Example: A minimal HLT1 sequence

    This is a minimal HLT1 sequence including only reconstruction
    algorithms and the example selections we created above. Calling
    generate using the returned sequence will produce an Allen sequence
    that automatically runs the example selection.

    First, copy the contents of `hlt1_pp_default.py` into `custom_sequence.py`.
    Modify the argument list to `HLT1Sequence` by adding the keyword argument
    `add_default_lines = False` and add the lines.
    
    Don't forget to add the hash strings that act as seed phrases in case of prescaling and postscaling.

    ```python
    hlt1_sequence = HLT1Sequence(
        layout_provider=velo_sequence["mep_layout"],
        initialize_lists=velo_sequence["initialize_lists"],
        full_event_list=velo_sequence["full_event_list"],
        velo_copy_track_hit_number=velo_sequence["velo_copy_track_hit_number"],
        velo_kalman_filter=pv_sequence["velo_kalman_filter"],
        prefix_sum_offsets_velo_track_hit_number=velo_sequence[
            "prefix_sum_offsets_velo_track_hit_number"],
        pv_beamline_multi_fitter=pv_sequence["pv_beamline_multi_fitter"],
        prefix_sum_forward_tracks=forward_sequence["prefix_sum_forward_tracks"],
        velo_consolidate_tracks=velo_sequence["velo_consolidate_tracks"],
        prefix_sum_ut_tracks=ut_sequence["prefix_sum_ut_tracks"],
        prefix_sum_ut_track_hit_number=ut_sequence[
            "prefix_sum_ut_track_hit_number"],
        ut_consolidate_tracks=ut_sequence["ut_consolidate_tracks"],
        prefix_sum_scifi_track_hit_number=forward_sequence[
            "prefix_sum_scifi_track_hit_number"],
        scifi_consolidate_tracks=forward_sequence["scifi_consolidate_tracks_t"],
        is_muon=muon_sequence["is_muon_t"],
        # Disable default lines
        add_default_lines=False)

    # New lines
    from definitions.HLT1Sequence import make_selection_gatherer
    from definitions.algorithms import *

    example_one_track_line = example_one_track_line_t(
        name="example_one_track_line",
        host_number_of_events_t=velo_sequence["initialize_lists"].host_number_of_events_t(),
        host_number_of_reconstructed_scifi_tracks_t=
        forward_sequence["prefix_sum_forward_tracks"].host_total_sum_holder_t(),
        dev_tracks_t=hlt1_sequence["kalman_velo_only"].dev_kf_tracks_t(),
        dev_event_list_t=velo_sequence["initialize_lists"].dev_event_list_t(),
        dev_track_offsets_t=forward_sequence["prefix_sum_forward_tracks"].
        dev_output_buffer_t(),
        dev_odin_raw_input_t=hlt1_sequence["odin_banks"].dev_raw_banks_t(),
        dev_odin_raw_input_offsets_t=hlt1_sequence["odin_banks"].dev_raw_offsets_t(),
        dev_mep_layout_t=hlt1_sequence["layout_provider"].dev_mep_layout_t(),
        pre_scaler_hash_string="example_one_track_line_pre",
        post_scaler_hash_string="example_one_track_line_post")

    example_two_track_line = example_two_track_line_t(
        name="example_two_track_line",
        host_number_of_events_t=velo_sequence["initialize_lists"].host_number_of_events_t(),
        host_number_of_svs_t=hlt1_sequence["prefix_sum_secondary_vertices"].
        host_total_sum_holder_t(),
        dev_svs_t=hlt1_sequence["fit_secondary_vertices"].dev_consolidated_svs_t(),
        dev_event_list_t=velo_sequence["initialize_lists"].dev_event_list_t(),
        dev_sv_offsets_t=hlt1_sequence["prefix_sum_secondary_vertices"].
        dev_output_buffer_t(),
        dev_odin_raw_input_t=hlt1_sequence["odin_banks"].dev_raw_banks_t(),
        dev_odin_raw_input_offsets_t=hlt1_sequence["odin_banks"].dev_raw_offsets_t(),
        dev_mep_layout_t=hlt1_sequence["layout_provider"].dev_mep_layout_t(),
        pre_scaler_hash_string="example_two_track_line_pre",
        post_scaler_hash_string="example_two_track_line_post")

    velo_micro_bias_line = velo_micro_bias_line_t(
        name="velo_micro_bias_line",
        host_number_of_events_t=velo_sequence["initialize_lists"].host_number_of_events_t(),
        dev_number_of_events_t=velo_sequence["initialize_lists"].dev_number_of_events_t(),
        dev_event_list_t=velo_sequence["full_event_list"].dev_event_list_t(),
        dev_offsets_velo_tracks_t=velo_sequence["velo_copy_track_hit_number"].dev_offsets_all_velo_tracks_t(),
        dev_offsets_velo_track_hit_number_t=velo_sequence["prefix_sum_offsets_velo_track_hit_number"].dev_output_buffer_t(),
        dev_odin_raw_input_t=hlt1_sequence["odin_banks"].dev_raw_banks_t(),
        dev_odin_raw_input_offsets_t=hlt1_sequence["odin_banks"].dev_raw_offsets_t(),
        dev_mep_layout_t=hlt1_sequence["layout_provider"].dev_mep_layout_t(),
        pre_scaler_hash_string="velo_micro_bias_line_pre",
        post_scaler_hash_string="velo_micro_bias_line_post")
    
    example_one_velo_track_line = example_one_velo_track_line_t(
        name="example_one_velo_track_line",
        host_number_of_events_t=velo_sequence["initialize_lists"].host_number_of_events_t(),
        host_number_of_reconstructed_velo_tracks_t=velo_sequence["velo_copy_track_hit_number"].host_number_of_reconstructed_velo_tracks_t(),
        dev_event_list_t=velo_sequence["full_event_list"].dev_event_list_t(),
        dev_odin_raw_input_t=hlt1_sequence["odin_banks"].dev_raw_banks_t(),
        dev_odin_raw_input_offsets_t=hlt1_sequence["odin_banks"].dev_raw_offsets_t(),
        dev_mep_layout_t=hlt1_sequence["layout_provider"].dev_mep_layout_t(),
        dev_track_offsets_t = velo_sequence["velo_copy_track_hit_number"].dev_offsets_all_velo_tracks_t(),
        dev_number_of_events_t=velo_sequence["initialize_lists"].dev_number_of_events_t(),
        dev_offsets_velo_track_hit_number_t = velo_sequence["prefix_sum_offsets_velo_track_hit_number"].dev_output_buffer_t(),
        pre_scaler_hash_string="example_one_velo_track_line_pre",
        post_scaler_hash_string="example_one_velo_track_line_post",
        minNHits="3")
        
    lines = (example_one_track_line, example_two_track_line, velo_micro_bias_line, example_one_velo_track_line)

    gatherer = make_selection_gatherer(
        lines, velo_sequence["initialize_lists"], hlt1_sequence["layout_provider"], hlt1_sequence["odin_banks"], name="gather_selections")

    # Compose final sequence with lines
    extend_sequence(compose_sequences(velo_sequence, pv_sequence, ut_sequence, forward_sequence,
                      muon_sequence, hlt1_sequence), *lines, gatherer).generate()
    ```

    Notice that all the values of the properties have to be given in a string even if the type of the property is an int or a float.
    Now, you should be able to build and run the newly generated `custom_sequence`.

    Notice also that if you're testing only one line, the tuple of lines becomes :
    `lines = (example_one_track_line,)`
    