/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration          *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

// Basic
#include "AlgorithmTypes.cuh"
#include "SingleLayerFCNN.cuh"

// Common
#include "States.cuh"

// Local
#include "DownstreamV2Structs.cuh"

namespace downstream_v2_define_scifi_candidates {

  using GhostKiller = Allen::MVAModels::SingleLayerFCNN<10, 8>;
  struct Parameters {
    // Basic
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    // Matching input
    DEVICE_INPUT(dev_matched_is_scifi_track_used_t, bool) dev_matched_is_scifi_track_used;

    // Scifi input
    HOST_INPUT(host_total_number_of_scifi_tracks_t, unsigned) host_total_number_of_scifi_tracks;
    DEVICE_INPUT(dev_offsets_seeding_tracks_t, unsigned) dev_offsets_seeding_tracks;
    DEVICE_INPUT(dev_seeding_states_t, MiniState) dev_seeding_states;
    DEVICE_INPUT(dev_seeding_chi2Y_t, float) dev_seeding_chi2Y;

    // UT input
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;

    // Select seeds
    DEVICE_OUTPUT(dev_downstream_seeds_t, Downstream::Structs::DownstreamSeed) dev_downstream_seeds;
    DEVICE_OUTPUT(dev_downstream_seed_offsets_t, unsigned) dev_downstream_seed_offsets;
    HOST_OUTPUT(host_total_number_of_downstream_seeds_t, unsigned) host_total_number_of_downstream_seeds;

    // Hits offsets for parallelization
    DEVICE_OUTPUT(dev_downstream_seed_hits_offsets_t, unsigned) dev_downstream_seed_hits_offsets;
    HOST_OUTPUT(host_total_number_of_downstream_candidates_t, unsigned) host_total_number_of_downstream_candidates;

    // Pairs
    DEVICE_OUTPUT(dev_downstream_candidates_t, ushort2) dev_downstream_candidates;
    DEVICE_OUTPUT(dev_downstream_candidate_offsets_t, unsigned) dev_downstream_candidate_offsets;
  };

  struct downstream_v2_define_scifi_candidates_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {128, 1, 1}, "block dimensions"};
    Allen::Property<float> m_y_layer_tolerance {this,
                                                "y_layer_tolerance",
                                                18.f,
                                                "the layer level tolerance window in Y"};
    Allen::Property<std::array<float, 2>> m_tx_tolerance {this,
                                                          "tx_tolerance",
                                                          {2.803916e-04f, 1.920496e-01f},
                                                          "the tolerance window in tx"};
    Allen::Property<float> m_seed_max_ghost_prob {this,
                                                  "seed_max_ghost_prob",
                                                  0.9,
                                                  "the maximum ghost probability for scifi seeds"};
    GhostKiller m_seed_ghost_killer {"seed_ghost_killer", "/GhostProbability/Hlt1_SciFiSeedGhostKiller.json"};
  };

  __global__ void downstream_v2_find_hit_ranges(
    Parameters,
    const UT::Constants::UTLayerGeometry* dev_ut_layer_geometry,
    float y_layer_tolerance,
    std::array<float, 2> tx_tolerance,
    float seed_max_ghost_prob,
    const GhostKiller::DeviceType*);
  __global__ void downstream_v2_compute_number_of_pairs(Parameters);
  __global__ void downstream_v2_fill_pairs(Parameters);
} // namespace downstream_v2_define_scifi_candidates
