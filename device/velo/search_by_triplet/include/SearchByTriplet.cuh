/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <cstdint>
#include <cfloat>
#include "ClusteringDefinitions.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "AlgorithmTypes.cuh"
#include "GenericContainerContracts.h"

namespace velo_search_by_triplet {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_total_number_of_velo_clusters_t, unsigned) host_total_number_of_velo_clusters;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_sorted_velo_cluster_container_t, char) dev_sorted_velo_cluster_container;
    DEVICE_INPUT(dev_offsets_estimated_input_size_t, unsigned) dev_offsets_estimated_input_size;
    DEVICE_INPUT(dev_module_cluster_num_t, unsigned) dev_module_cluster_num;
    DEVICE_OUTPUT(dev_tracks_t, Velo::TrackHits) dev_tracks;
    DEVICE_OUTPUT(dev_tracklets_t, Velo::TrackletHits) dev_tracklets;
    DEVICE_OUTPUT(dev_tracks_to_follow_t, unsigned) dev_tracks_to_follow;
    DEVICE_OUTPUT(dev_three_hit_tracks_t, Velo::TrackletHits) dev_three_hit_tracks;
    DEVICE_OUTPUT(dev_hit_used_t, uint8_t) dev_hit_used;
    DEVICE_OUTPUT(dev_atomics_velo_t, unsigned) dev_atomics_velo;
    DEVICE_OUTPUT(dev_rel_indices_t, unsigned short) dev_rel_indices;
    DEVICE_OUTPUT(dev_offsets_velo_tracks_t, unsigned) dev_offsets_velo_tracks;
    HOST_OUTPUT(host_number_of_velo_tracks_at_least_four_hits_t, unsigned)
    host_number_of_velo_tracks_at_least_four_hits;
  };

  // Define pre and postconditions
  struct cluster_container_checks : public Allen::contract::Precondition {
    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;
  };

  struct track_container_checks : public Allen::contract::Postcondition {
    void operator()(
      const ArgumentReferences<Parameters>&,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context&) const;
  };

  __device__ inline std::tuple<int16_t, int16_t> find_forward_candidate(
    const Velo::ModulePair& module_pair,
    const int16_t* hit_phis,
    const Velo::HitBase& h0,
    const float tx,
    const float ty,
    const float dz,
    const int16_t phi_tolerance);

  __device__ void track_seeding(
    Velo::ConstClusters& velo_cluster_container,
    const Velo::ModulePair& previous_module_pair,
    const Velo::ModulePair& current_module_pair,
    const Velo::ModulePair& next_module_pair,
    uint8_t* hit_used,
    Velo::TrackletHits* tracklets,
    unsigned* tracks_to_follow,
    uint16_t* h1_indices,
    unsigned* dev_atomics_velo,
    const float max_scatter,
    const int16_t phi_tolerance,
    const unsigned h0_candidates_to_consider);

  __device__ void track_forwarding(
    Velo::ConstClusters& velo_cluster_container,
    uint8_t* hit_used,
    const Velo::ModulePair& next_module_pair,
    const unsigned diff_ttf,
    unsigned* tracks_to_follow,
    Velo::TrackletHits* three_hit_tracks,
    const unsigned prev_ttf,
    Velo::TrackletHits* tracklets,
    Velo::TrackHits* tracks,
    unsigned* dev_atomics_velo,
    unsigned* dev_number_of_velo_tracks,
    const int16_t phi_tolerance,
    const float max_scatter,
    const unsigned max_skipped_modules,
    const unsigned event_number);

  __global__ void velo_search_by_triplet(
    Parameters,
    const VeloGeometry*,
    const float phi_tolerance,
    const float max_scatter,
    const unsigned max_skipped_modules,
    const unsigned missing_module_pairs);

  struct velo_search_by_triplet_t : public DeviceAlgorithm, Parameters {
    // Register contracts for this algorithm
    using contracts = std::tuple<cluster_container_checks, track_container_checks>;

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<float> m_tolerance {this, "phi_tolerance", 0.045f, "tolerance in phi"};
    Allen::Property<float> m_max_scatter {this, "max_scatter", 0.08f, "maximum scatter for seeding and forwarding"};
    Allen::Property<unsigned> m_skip {this, "max_skipped_modules", 1, "skipped modules"};
    Allen::Property<unsigned> m_missing_module_pairs {this, "missing_module_pairs", 0, "missing module pairs bitmask"};
    Allen::Property<unsigned> m_block_dim_x {this, "block_dim_x", 64, "block dimension x"};
  };
} // namespace velo_search_by_triplet
