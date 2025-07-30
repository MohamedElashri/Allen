/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include "tracks_ACsplit_counters.cuh"

namespace tracks_ACsplit {
  struct Parameters {
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_A_side_t, unsigned)
    host_number_of_reconstructed_velo_tracks_A_side;
    HOST_INPUT(host_number_of_reconstructed_velo_tracks_C_side_t, unsigned)
    host_number_of_reconstructed_velo_tracks_C_side;
    HOST_INPUT(host_total_number_of_velo_clusters_t, unsigned) host_total_number_of_velo_clusters;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;

    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_tracks_t, Velo::TrackHits) dev_tracks;
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned) dev_offsets_all_velo_tracks;
    DEVICE_INPUT(dev_sorted_velo_cluster_container_t, char) dev_sorted_velo_cluster_container;
    DEVICE_INPUT(dev_offsets_estimated_input_size_t, unsigned) dev_offsets_estimated_input_size;
    DEVICE_INPUT(dev_three_hit_tracks_output_t, Velo::TrackletHits) dev_three_hit_tracks_output;
    DEVICE_INPUT(dev_offsets_number_of_three_hit_tracks_filtered_t, unsigned)
    dev_offsets_number_of_three_hit_tracks_filtered;
    DEVICE_INPUT(dev_offsets_velo_tracks_A_side_t, unsigned) dev_offsets_velo_tracks_A_side;
    DEVICE_INPUT(dev_offsets_velo_tracks_C_side_t, unsigned) dev_offsets_velo_tracks_C_side;

    // Velo side A
    DEVICE_OUTPUT(dev_tracks_A_side_t, Velo::TrackHits) dev_tracks_A_side;
    DEVICE_OUTPUT(dev_offsets_velo_track_hit_number_A_side_t, unsigned) dev_offsets_velo_track_hit_number_A_side;
    HOST_OUTPUT(host_accumulated_number_of_hits_in_velo_tracks_A_side_t, unsigned)
    host_accumulated_number_of_hits_in_velo_tracks_A_side;
    DEVICE_OUTPUT(dev_three_hit_tracks_output_A_side_t, Velo::TrackletHits) dev_three_hit_tracks_output_A_side;

    // Velo side C
    DEVICE_OUTPUT(dev_tracks_C_side_t, Velo::TrackHits) dev_tracks_C_side;
    DEVICE_OUTPUT(dev_offsets_velo_track_hit_number_C_side_t, unsigned) dev_offsets_velo_track_hit_number_C_side;
    HOST_OUTPUT(host_accumulated_number_of_hits_in_velo_tracks_C_side_t, unsigned)
    host_accumulated_number_of_hits_in_velo_tracks_C_side;
    DEVICE_OUTPUT(dev_three_hit_tracks_output_C_side_t, Velo::TrackletHits) dev_three_hit_tracks_output_C_side;
  };

  __global__ void tracks_ACsplit(Parameters, const bool);

  struct tracks_ACsplit_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {32, 1, 1}, "block dimensions"};
    Allen::Property<std::string> splitting_algorithm {this, "splitting_algorithm", "A/C split", "splitting_algorithm"};
  };
} // namespace tracks_ACsplit
