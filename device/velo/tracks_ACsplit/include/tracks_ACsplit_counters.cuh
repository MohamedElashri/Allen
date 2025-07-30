/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include <string>

#include "Common.h"
#include "AlgorithmTypes.cuh"
#include "VeloEventModel.cuh"
#include "ClusteringDefinitions.cuh"

namespace tracks_ACsplit_counters {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_three_hit_tracks_output_t, Velo::TrackletHits) dev_three_hit_tracks_output;
    DEVICE_INPUT(dev_tracks_t, Velo::TrackHits) dev_tracks;
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned) dev_offsets_all_velo_tracks;
    DEVICE_INPUT(dev_offsets_number_of_three_hit_tracks_filtered_t, unsigned)
    dev_offsets_number_of_three_hit_tracks_filtered;
    DEVICE_INPUT(dev_sorted_velo_cluster_container_t, char) dev_sorted_velo_cluster_container;
    DEVICE_INPUT(dev_offsets_estimated_input_size_t, unsigned) dev_offsets_estimated_input_size;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;

    // Velo side A
    DEVICE_OUTPUT(dev_offsets_number_of_three_hit_tracks_filtered_A_side_t, unsigned)
    dev_offsets_number_of_three_hit_tracks_filtered_A_side;
    HOST_OUTPUT(host_number_of_three_hit_tracks_filtered_A_side_t, unsigned)
    host_number_of_three_hit_tracks_filtered_A_side;
    DEVICE_OUTPUT(dev_offsets_velo_tracks_A_side_t, unsigned) dev_offsets_velo_tracks_A_side;
    HOST_OUTPUT(host_number_of_reconstructed_velo_tracks_A_side_t, unsigned)
    host_number_of_reconstructed_velo_tracks_A_side;

    // Velo side C
    DEVICE_OUTPUT(dev_offsets_number_of_three_hit_tracks_filtered_C_side_t, unsigned)
    dev_offsets_number_of_three_hit_tracks_filtered_C_side;
    HOST_OUTPUT(host_number_of_three_hit_tracks_filtered_C_side_t, unsigned)
    host_number_of_three_hit_tracks_filtered_C_side;
    DEVICE_OUTPUT(dev_offsets_velo_tracks_C_side_t, unsigned) dev_offsets_velo_tracks_C_side;
    HOST_OUTPUT(host_number_of_reconstructed_velo_tracks_C_side_t, unsigned)
    host_number_of_reconstructed_velo_tracks_C_side;
  };

  __global__ void tracks_ACsplit_counters(Parameters, const bool);

  //=============================================================================
  // Determine the velo side of the track
  //=============================================================================

  __device__ inline unsigned velo_track_in_A_side(
    const Velo::ConstClusters velo_cluster_container,
    const Velo::TrackHits& track)
  {
    unsigned A_side_hits = 0;
    // Side is determined by the number of hits that belong to it.
    // Tracks with the same number of hits from both side, are considered C side tracks
    for (unsigned i = 0; i < track.hitsNum; ++i) {
      const auto hit_index = track.hits[i];
      A_side_hits += get_module_number(velo_cluster_container.id(hit_index)) % 2;
    }

    if (A_side_hits == track.hitsNum - A_side_hits) {
      return 2;
    }
    else if (A_side_hits > track.hitsNum - A_side_hits) {
      return 1;
    }

    return 0;
  }

  __device__ inline bool random_selection(
    const Velo::ConstClusters velo_cluster_container,
    const Velo::TrackHits& track)
  {
    const auto index_hitFirst = track.hits[0];
    const auto index_hitLast = track.hits[track.hitsNum - 1];
    const auto r_hitFirst = velo_cluster_container.x(index_hitFirst) * velo_cluster_container.x(index_hitFirst) +
                            velo_cluster_container.y(index_hitFirst) * velo_cluster_container.y(index_hitFirst);
    const auto r_hitLast = velo_cluster_container.x(index_hitLast) * velo_cluster_container.x(index_hitLast) +
                           velo_cluster_container.y(index_hitLast) * velo_cluster_container.y(index_hitLast);

    if (r_hitFirst > r_hitLast) {
      return index_hitFirst % 2;
    }
    else {
      return index_hitLast % 2;
    }
  }

  struct tracks_ACsplit_counters_t : public DeviceAlgorithm, Parameters {
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
} // namespace tracks_ACsplit_counters
