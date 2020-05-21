
# Table of Contents

1.  [Allen: Adding a new selection](#orgec93f80)
    1.  [Types of selections](#orgf63e834)
        1.  [`SpecialLine`](#org17c80a2)
        2.  [`OneTrackLine`](#org219209d)
        3.  [`TwoTrackLine`](#org1e461fd)
        4.  [`ThreeTrackLine`](#orgd5c01cf)
        5.  [`FourTrackLine`](#org20a5021)
    2.  [Adding a new selection](#org9dddbc8)
        1.  [Writing the CUDA code](#org14eaf8f)
        2.  [Adding your selection to the Allen sequence](#org3fe70a8)


<a id="orgec93f80"></a>

# Allen: Adding a new selection

This tutorial will cover adding trigger selections to Allen using the
main reconstruction sequence. Selections requiring special
reconstructions will not be covered.


<a id="orgf63e834"></a>

## Types of selections


<a id="org17c80a2"></a>

### `SpecialLine`

These make trigger selections based on event-level information. Right
now this includes the ODIN raw bank and the number of reconstructed
velo tracks in the event. This includes minimum bias and lumi lines.


<a id="org219209d"></a>

### `OneTrackLine`

These trigger on single Kalman filtered long (Velo-UT-SciFi)
tracks. These are stored in the device buffer type
`dev_kf_tracks_t`. The structure of these tracks is defined in
`cuda/kalman/ParKalman/include/ParKalmanDefinitions.cuh`. This
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


<a id="org1e461fd"></a>

### `TwoTrackLine`

These trigger on secondary vertices constructed from 2 Kalman filtered
long tracks defined in
`cuda/vertex_fit/common/include/VertexDefinitions.cuh`. These tracks
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


<a id="orgd5c01cf"></a>

### `ThreeTrackLine`

Coming soon.


<a id="org20a5021"></a>

### `FourTrackLine`

Coming soon.


<a id="org9dddbc8"></a>

## Adding a new selection


<a id="org14eaf8f"></a>

### Writing the CUDA code

The python parser requires that each selection has exactly one
corresponding header file in `cuda/selections/lines/include`. Each
selection is defined within a namespace that holds relevant
parameters. The line itself is a struct inheriting from the
corresponding line type defined in
`cuda/selections/Hlt1/include/LineInfo.cuh`. This struct has a data
member name that stores the name of the line. Optionally it will also
have a data member `scale_factor` that determines the line's
postscale. If this is not present, the line will have a postscale
of 1. Finally the struct includes a device member function function
that takes the trigger candidate as an argument and returns a bool.

1.  Example: High-pT displaced track selection

    As an example, we'll create a line that triggers on highly displaced,
    high-pT single tracks and has a postscale of 0.5. We will create the
    file `cuda/selections/lines/include/ExampleOneTrack.cuh`.
    
        #pragma once
        
        #include "LineInfo.cuh"
        #include "ParKalmanDefinitions.cuh"
        #include "SystemOfUnits.h"
        
        namespace ExampleOneTrack {
        
          // Parameters.
          constexpr float minPt = 10000.0f / Gaudi::Units::MeV;
          constexpr float minIPChi2 = 25.0f;
        
          // Line struct.
          struct ExampleOneTrack_t : public Hlt1::OneTrackLine {
        
            // Name of the line.
            constexpr static auto name {"ExampleOneTrack"};
        
            // Postscale.
            constexpr static auto scale_factor = 0.5f;
        
            // Selection function.
            static __device__ bool function(const ParKalmanFilter::FittedTrack& track)
            {
              const bool decision = track.pt() > minPt && track.ipChi2 > minIPChi2;
              return decision;
            }
        
          };
        
        } // namespace ExampleOneTrack

2.  Example: Displaced 2-body selection

    Here we'll create an example 2-track line that selects displaced
    secondary vertices with no postscale. We'll put this in
    `cuda/selections/lines/include/ExampleTwoTrack.cuh`.
    
        #pragma once
        
        #include "LineInfo.cuh"
        #include "VertexDefinitions.cuh"
        #include "SystemOfUnits.h"
        
        namespace ExampleTwoTrack {
        
          // Parameters.
          constexpr float minComboPt = 2000.0f / Gaudi::Units::MeV;
          constexpr float minTrackPt = 500.0f / Gaudi::Units::MeV;
          constexpr float minTrackIPChi2 = 25.0f;
        
          // Line struct.
          struct ExampleTwoTrack_t : public Hlt1::TwoTrackLine {
        
            // Name of the line.
            constexpr static auto name {"ExampleTwoTrack"};
        
            // Selection function.
            static __device__ bool function(const VertexFit::TrackMVAVertex vertex)
            {
              // Make sure the vertex fit succeeded.
              if (vertex.chi2 < 0) {
                return false;
              }
        
              const bool decision = vertex.pt() > minComboPt && 
                vertex.minpt > minTrackPt &&
                vertex.minipchi2 > minTrackIPChi2;
              return decision;
            }
        
          };
        
        } // namespace ExampleTwoTrack


<a id="org3fe70a8"></a>

### Adding your selection to the Allen sequence

Selections are added to the Allen sequence similarly to
algorithms. After creating the selection source code, a new sequence
must be generated. Head to `configuration/sequences` and add a new
configuration file.

The selection can then be added to a sequence. The sequence header file
can then be generated in the usual way. The line will automatically be
included in a tuple of selections, which will be accessed using the
`LineTraverser`. The traverser evaluates the selections on candidates
stored in the buffers corresponding to the line type. In addition, the
traverser will handle adding the selection information to the rate
checker, DecReports, and SelReports.

1.  Example: A minimal HLT1 sequence

    This is a minimal HLT1 sequence including only reconstruction
    algorithms and the example selections we created above. Calling
    generate using the returned sequence will produce an Allen sequence
    that automatically runs the example selection.

    First, copy the contents of `hlt1_pp_default.py` into `custom_sequence.py`.
    Modify the argument list to `HLT1Sequence` by adding the keyword argument
    `add_default_lines = False`, and add the lines:

        hlt1_sequence = HLT1Sequence(
            initialize_lists=velo_sequence["initialize_lists"],
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
        ExampleOneTrack_line = ExampleOneTrack_t()
        ExampleTwoTrack_line = ExampleTwoTrack_t()

        # Compose final sequence with lines
        compose_sequences(velo_sequence, pv_sequence, ut_sequence, forward_sequence,
                          muon_sequence, hlt1_sequence, ExampleOneTrack_line,
                          ExampleTwoTrack_line).generate()

    Now, you should be able to build and run the newly generated `custom_sequence`.
    