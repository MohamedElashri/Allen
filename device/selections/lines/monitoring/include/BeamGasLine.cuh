/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "Line.cuh"
#include "VeloConsolidated.cuh"

namespace beam_gas_line {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_t, unsigned) host_number_of_reconstructed_velo_tracks;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    MASK_OUTPUT(dev_selected_events_t) dev_selected_events;
    HOST_OUTPUT(host_selected_events_size_t, unsigned) host_selected_events_size;
    DEVICE_OUTPUT(dev_selected_events_size_t, unsigned) dev_selected_events_size;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    DEVICE_INPUT(dev_offsets_velo_tracks_t, unsigned) dev_offsets_velo_tracks;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, unsigned) dev_offsets_velo_track_hit_number;
    DEVICE_INPUT(dev_odin_raw_input_t, char) dev_odin_raw_input;
    DEVICE_INPUT(dev_odin_raw_input_offsets_t, unsigned) dev_odin_raw_input_offsets;
    DEVICE_INPUT(dev_mep_layout_t, unsigned) dev_mep_layout;
    DEVICE_OUTPUT(dev_decisions_t, bool) dev_decisions;
    DEVICE_OUTPUT(dev_decisions_offsets_t, unsigned) dev_decisions_offsets;
    HOST_OUTPUT(host_post_scaler_t, float) host_post_scaler;
    HOST_OUTPUT(host_post_scaler_hash_t, uint32_t) host_post_scaler_hash;
    DEVICE_OUTPUT(dev_particle_container_ptr_t, Allen::IMultiEventContainer*)
    dev_particle_container_ptr;
    PROPERTY(pre_scaler_t, "pre_scaler", "Pre-scaling factor", float) pre_scaler;
    PROPERTY(post_scaler_t, "post_scaler", "Post-scaling factor", float) post_scaler;
    PROPERTY(pre_scaler_hash_string_t, "pre_scaler_hash_string", "Pre-scaling hash string", std::string);
    PROPERTY(post_scaler_hash_string_t, "post_scaler_hash_string", "Post-scaling hash string", std::string);
    PROPERTY(min_velo_tracks_t, "min_velo_tracks", "Minimum number of VELO tracks", unsigned) min_velo_tracks;
    PROPERTY(beam_crossing_type_t, "beam_crossing_type", "ODIN beam crossing type [0-3]", unsigned) beam_crossing_type;
    PROPERTY(minNHits_t, "minNHits", "min number of hits of velo track", unsigned) minNHits;
    PROPERTY(minZ_t, "minZ", "min z coordinate for accepted velo track POCA", float) minZ;
    PROPERTY(maxZ_t, "maxZ", "max z coordinate for accepted velo track POCA", float) maxZ;
  };

  struct beam_gas_line_t : public SelectionAlgorithm, Parameters, Line<beam_gas_line_t, Parameters> {

    __device__ static std::tuple<const unsigned, const unsigned, const unsigned, const float>
    get_input(const Parameters& parameters, const unsigned event_number, const unsigned i);

    __device__ static bool select(
      const Parameters& parameters,
      std::tuple<const unsigned, const unsigned, const unsigned, const float> input);

    static unsigned get_decisions_size(ArgumentReferences<Parameters>& arguments)
    {
      return first<typename Parameters::host_number_of_reconstructed_velo_tracks_t>(arguments);
    }

    __device__ static unsigned input_size(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_offsets_velo_tracks[event_number + 1] - parameters.dev_offsets_velo_tracks[event_number];
    }

    __device__ static unsigned offset(const Parameters& parameters, const unsigned event_number)
    {
      return parameters.dev_offsets_velo_tracks[event_number];
    }

  private:
    Property<pre_scaler_t> m_pre_scaler {this, 1.f};
    Property<post_scaler_t> m_post_scaler {this, 1e-3f};
    Property<pre_scaler_hash_string_t> m_pre_scaler_hash_string {this, ""};
    Property<post_scaler_hash_string_t> m_post_scaler_hash_string {this, ""};
    Property<min_velo_tracks_t> m_min_velo_tracks {this, 1};
    Property<beam_crossing_type_t> m_beam_crossing_type {this, 1};
    Property<minNHits_t> m_minNHits {this, 12};
    Property<minZ_t> m_minZ {this, -550.f * Gaudi::Units::mm};
    Property<maxZ_t> m_maxZ {this, -300.f * Gaudi::Units::mm};
  };
} // namespace beam_gas_line
