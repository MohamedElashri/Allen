/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration          *
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

// Event Model
#include "UTEventModel.cuh"
#include "SciFiEventModel.cuh"
#include "SciFiConsolidated.cuh"
#include "NeuralNetwork.cuh"

// Local
#include "DownstreamConstants.cuh"
#include "DownstreamStructs.cuh"
#include "DownstreamExtrapolation.cuh"
#include "DownstreamHelper.cuh"
#include "UTHitCache.cuh"

#include "AllenMonitoring.h"

/**
 * @brief This is definition file for downstream_find_hits algorithm
 * implemented in downstream_find_hits.cu
 */
namespace downstream_find_hits {

  struct Parameters {
    // Basic
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;

    // Matching input
    DEVICE_INPUT(dev_matched_is_scifi_track_used_t, bool) dev_matched_is_scifi_track_used;

    // Scifi input
    // DEVICE_INPUT(dev_scifi_track_selection_t, bool) dev_scifi_track_selection;
    DEVICE_INPUT(dev_offsets_seeding_t, unsigned) dev_offsets_seeding;
    DEVICE_INPUT(dev_seeding_states_t, MiniState) dev_seeding_states;
    DEVICE_INPUT(dev_seeding_qop_t, float) dev_seeding_qop;
    DEVICE_INPUT(dev_seeding_chi2Y_t, float) dev_seeding_chi2Y;

    // UT input
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, unsigned) dev_ut_hit_offsets;
    HOST_INPUT(host_accumulated_number_of_ut_hits_t, unsigned) host_accumulated_number_of_ut_hits;

    // Outputs
    DEVICE_OUTPUT(dev_findhits_output_t, Downstream::DownstreamStructs::DownstreamHits) dev_findhits_output;
    DEVICE_OUTPUT(dev_findhits_extrapolation_t, Downstream::DownstreamStructs::ExtrapolationData)
    dev_findhits_extrapolation;
    DEVICE_OUTPUT(dev_findhits_candidate_cache_t, Downstream::DownstreamStructs::CandidateCache)
    dev_findhits_candidate_cache;
    DEVICE_OUTPUT(dev_findhits_selected_scifi_tracks_t, Downstream::DownstreamStructs::SelectedSciFiTrack)
    dev_findhits_selected_scifi_tracks;

    // Output offsets
    DEVICE_OUTPUT(dev_findhits_num_output_t, unsigned) dev_findhits_num_output;
    DEVICE_OUTPUT(dev_findhits_num_selected_scifi_t, unsigned) dev_findhits_num_selected_scifi;
    DEVICE_OUTPUT(dev_findhits_output_selected_scifi_offsets_t, unsigned) dev_findhits_output_selected_scifi_offsets;

    // Properties
    PROPERTY(
      ttracks_probability_threshold_t,
      "ttracks_probability_threshold",
      "the threshold of the T track propability",
      float)
    ttracks_probability_threshold;
    PROPERTY(require_four_ut_hits_t, "require_four_ut_hits", "Require 4 UT hits to create downstream tracks", bool)
    require_four_ut_hits;

    // Block size
    PROPERTY(
      num_threads_create_candidates_t,
      "num_threads_create_candidates",
      "number of threads for candidate creation",
      DeviceDimensions)
    num_threads_create_candidates;
    PROPERTY(
      num_threads_find_rest_hits_t,
      "num_threads_find_rest_hits",
      "number of threads for finding rest of hits",
      DeviceDimensions)
    num_threads_find_rest_hits;

    PROPERTY(
      enable_constant_tolerance_window_t,
      "enable_constant_tolerance_window",
      "switch for constant tolerance window",
      bool)
    enable_constant_tolerance_window;

    PROPERTY(
      tolerance_window_x1_multiplier_t,
      "tolerance_window_x1_multiplier",
      "constant value, at which defaut value is multiplied",
      float)
    tolerance_window_x1_multiplier;

    PROPERTY(
      tolerance_window_y1_multiplier_t,
      "tolerance_window_y1_multiplier",
      "constant value, at which defaut value is multiplied",
      float)
    tolerance_window_y1_multiplier;

    PROPERTY(
      tolerance_window_x2_multiplier_t,
      "tolerance_window_x2_multiplier",
      "constant value, at which defaut value is multiplied",
      float)
    tolerance_window_x2_multiplier;

    PROPERTY(
      tolerance_window_y2_multiplier_t,
      "tolerance_window_y2_multiplier",
      "constant value, at which defaut value is multiplied",
      float)
    tolerance_window_y2_multiplier;

    PROPERTY(
      tolerance_window_x3_multiplier_t,
      "tolerance_window_x3_multiplier",
      "constant value, at which defaut value is multiplied",
      float)
    tolerance_window_x3_multiplier;

    PROPERTY(
      tolerance_window_y3_multiplier_t,
      "tolerance_window_y3_multiplier",
      "constant value, at which defaut value is multiplied",
      float)
    tolerance_window_y3_multiplier;

    PROPERTY(
      tolerance_window_x4_multiplier_t,
      "tolerance_window_x4_multiplier",
      "constant value, at which defaut value is multiplied",
      float)
    tolerance_window_x4_multiplier;

    PROPERTY(
      tolerance_window_y4_multiplier_t,
      "tolerance_window_y4_multiplier",
      "constant value, at which defaut value is multiplied",
      float)
    tolerance_window_y4_multiplier;
  };

#if defined(TARGET_DEVICE_CUDA)
#if __CUDA_ARCH__ >= 800 // Ampere (A5000)
  // downstream_create_candidates has 48 register / thread
  // downstream_find_rest_hits has 40 register / thread
  __device__ static constexpr unsigned int MaxCacheSize_CreateCandidates = 1472 - 1; // Need extra bits for counters
  __device__ static constexpr unsigned int MaxCacheSize_FindRestHits = 1472;
#else // Volta, Turing:
  __device__ static constexpr unsigned int MaxCacheSize_CreateCandidates = 1344 - 1; // Need extra bits for counters
  __device__ static constexpr unsigned int MaxCacheSize_FindRestHits = 1344;
#endif
#else // CPU, HIP
  __device__ static constexpr unsigned int MaxCacheSize_CreateCandidates = 1;
  __device__ static constexpr unsigned int MaxCacheSize_FindRestHits = 1;
#endif
  using UTHitsCache_CreateCandidates = UT::SmartHitsCache<MaxCacheSize_CreateCandidates>;
  using UTHitsCache_FindRestHits = UT::SmartHitsCache<MaxCacheSize_FindRestHits>;

  template<bool filter_used_scifi_seeds, bool use_constant_tolerance_window>
  __global__ void downstream_create_candidates(
    Parameters parameters,
    const unsigned* dev_unique_x_sector_layer_offsets,
    const float* dev_unique_sector_xs,
    const float* dev_magnet_polarity,
    const UT::Constants::PerLayerInfo* dev_mean_layer_info,
    const Allen::NeuralNetwork::Model::TTrackSelector* dev_ttrack_selector,
    [[maybe_unused]] Allen::Monitoring::Counter<>::DeviceType dev_n_overflow_downstream_tracking);

  template<bool require_four_hits, bool use_constant_tolerance_window>
  __global__ void downstream_find_rest_hits(
    Parameters parameters,
    const unsigned* dev_unique_x_sector_layer_offsets,
    const float* dev_unique_sector_xs,
    const UT::Constants::PerLayerInfo* dev_mean_layer_info);

  struct downstream_find_hits_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Monitoring::Counter<> m_n_overflow_downstream_tracking {this, "n_overflow_downstream_tracking"};
    Property<ttracks_probability_threshold_t> m_ttracks_probability_threshold {this, 0.5};
    Property<require_four_ut_hits_t> m_require_four_ut_hits {this, true};
    Property<num_threads_create_candidates_t> m_num_threads_create_candidates {this, {{64, 1, 1}}};
    Property<num_threads_find_rest_hits_t> m_num_threads_find_rest_hits {this, {{192, 1, 1}}};
    Property<enable_constant_tolerance_window_t> m_enable_constant_tolerance_window {this, false};
    Property<tolerance_window_x1_multiplier_t> m_tolerance_window_x1_multiplier {this, 1.f};
    Property<tolerance_window_y1_multiplier_t> m_tolerance_window_y1_multiplier {this, 1.f};
    Property<tolerance_window_x2_multiplier_t> m_tolerance_window_x2_multiplier {this, 1.f};
    Property<tolerance_window_y2_multiplier_t> m_tolerance_window_y2_multiplier {this, 1.f};
    Property<tolerance_window_x3_multiplier_t> m_tolerance_window_x3_multiplier {this, 1.f};
    Property<tolerance_window_y3_multiplier_t> m_tolerance_window_y3_multiplier {this, 1.f};
    Property<tolerance_window_x4_multiplier_t> m_tolerance_window_x4_multiplier {this, 1.f};
    Property<tolerance_window_y4_multiplier_t> m_tolerance_window_y4_multiplier {this, 1.f};
  };

} // namespace downstream_find_hits
