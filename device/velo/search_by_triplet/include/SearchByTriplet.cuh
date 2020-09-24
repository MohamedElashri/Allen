/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cstdint>
#include <cfloat>
#include "ClusteringDefinitions.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace velo_search_by_triplet {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events),
    (HOST_INPUT(host_total_number_of_velo_clusters_t, unsigned), host_total_number_of_velo_clusters),
    (DEVICE_INPUT(dev_sorted_velo_cluster_container_t, char), dev_sorted_velo_cluster_container),
    (DEVICE_INPUT(dev_offsets_estimated_input_size_t, unsigned), dev_offsets_estimated_input_size),
    (DEVICE_INPUT(dev_module_cluster_num_t, unsigned), dev_module_cluster_num),
    (DEVICE_INPUT(dev_hit_phi_t, int16_t), dev_hit_phi),
    (DEVICE_OUTPUT(dev_tracks_t, Velo::TrackHits), dev_tracks),
    (DEVICE_OUTPUT(dev_tracklets_t, Velo::TrackletHits), dev_tracklets),
    (DEVICE_OUTPUT(dev_tracks_to_follow_t, unsigned), dev_tracks_to_follow),
    (DEVICE_OUTPUT(dev_three_hit_tracks_t, Velo::TrackletHits), dev_three_hit_tracks),
    (DEVICE_OUTPUT(dev_hit_used_t, bool), dev_hit_used),
    (DEVICE_OUTPUT(dev_atomics_velo_t, unsigned), dev_atomics_velo),
    (DEVICE_OUTPUT(dev_rel_indices_t, unsigned short), dev_rel_indices),
    (DEVICE_OUTPUT(dev_number_of_velo_tracks_t, unsigned), dev_number_of_velo_tracks),

    // Tolerance in phi
    (PROPERTY(phi_tolerance_t, "phi_tolerance", "tolerance in phi", float), phi_tolerance),

    // Max scatter for forming triplets (seeding) and forwarding
    (PROPERTY(max_scatter_t, "max_scatter", "maximum scatter for seeding and forwarding", float), max_scatter),

    // Maximum number of skipped modules allowed for a track
    // before storing it
    (PROPERTY(max_skipped_modules_t, "max_skipped_modules", "skipped modules", unsigned), max_skipped_modules),

    // Block dimension x of kernel
    (PROPERTY(block_dim_x_t, "block_dim_x", "block dimension x", unsigned), block_dim_x))

  __global__ void velo_search_by_triplet(Parameters, const VeloGeometry*);

  struct velo_search_by_triplet_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<phi_tolerance_t> m_tolerance {this, 0.045f};
    Property<max_scatter_t> m_max_scatter {this, 0.08f};
    Property<max_skipped_modules_t> m_skip {this, 1};
    Property<block_dim_x_t> m_block_dim_x {this, 64};
  };
} // namespace velo_search_by_triplet
