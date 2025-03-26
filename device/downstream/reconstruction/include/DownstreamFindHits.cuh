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
#include "SingleLayerFCNN.cuh"

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

  constexpr unsigned MaxNumIteration = 2;
  using TTrackSelector = Allen::MVAModels::SingleLayerFCNN<4, 16>;

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
  };

#if defined(TARGET_DEVICE_CUDA)
#if __CUDA_ARCH__ >= 800 // Ampere (A5000)
  // downstream_create_candidates has 48 register / thread
  // downstream_find_rest_hits has 40 register / thread
  __device__ static constexpr unsigned int MaxCacheSize_CreateCandidates = 1472 - 2; // Need extra bits for counters
  __device__ static constexpr unsigned int MaxCacheSize_FindRestHits = 1472;
#else // Volta, Turing:
  __device__ static constexpr unsigned int MaxCacheSize_CreateCandidates = 1344 - 2; // Need extra bits for counters
  __device__ static constexpr unsigned int MaxCacheSize_FindRestHits = 1344;
#endif
#else // CPU, HIP
  __device__ static constexpr unsigned int MaxCacheSize_CreateCandidates = 1;
  __device__ static constexpr unsigned int MaxCacheSize_FindRestHits = 1;
#endif
  using UTHitsCache_CreateCandidates = UTHitCache::FullHitCache_8Bytes<MaxCacheSize_CreateCandidates>;
  using UTHitsCache_FindRestHits = UTHitCache::FullHitCache_8Bytes<MaxCacheSize_FindRestHits>;

  template<bool filter_used_scifi_seeds, bool use_constant_tolerance_window>
  __global__ void downstream_create_candidates(
    Parameters parameters,
    const float* dev_magnet_polarity,
    const float tolerance_window_x4_multiplier,
    const float tolerance_window_y4_multiplier,
    const float ttracks_probability_threshold,
    const UT::Constants::UTLayerGeometry* dev_ut_layer_geometry,
    const TTrackSelector::DeviceType* dev_ttrack_selector,
    [[maybe_unused]] Allen::Monitoring::Counter<>::DeviceType dev_n_overflow_downstream_tracking);

  template<bool require_four_hits, bool use_constant_tolerance_window>
  __global__ void downstream_find_rest_hits(
    Parameters parameters,
    const UT::Constants::UTLayerGeometry* dev_ut_layer_geometry,
    const float tolerance_window_x1_multiplier,
    const float tolerance_window_x2_multiplier,
    const float tolerance_window_x3_multiplier,
    const float tolerance_window_y1_multiplier,
    const float tolerance_window_y2_multiplier,
    const float tolerance_window_y3_multiplier);

  struct downstream_find_hits_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Monitoring::Counter<> m_n_overflow_downstream_tracking {this, "n_overflow_downstream_tracking"};
    Allen::Property<float> m_ttracks_probability_threshold {this,
                                                            "ttracks_probability_threshold",
                                                            0.5,
                                                            "the threshold of the T track propability"};
    Allen::Property<bool> m_require_four_ut_hits {this,
                                                  "require_four_ut_hits",
                                                  true,
                                                  "Require 4 UT hits to create downstream tracks"};
    Allen::Property<dim3> m_num_threads_create_candidates {this,
                                                           "num_threads_create_candidates",
                                                           {64, 1, 1},
                                                           "number of threads for candidate creation"};
    Allen::Property<dim3> m_num_threads_find_rest_hits {this,
                                                        "num_threads_find_rest_hits",
                                                        {192, 1, 1},
                                                        "number of threads for finding rest of hits"};
    Allen::Property<bool> m_enable_constant_tolerance_window {this,
                                                              "enable_constant_tolerance_window",
                                                              false,
                                                              "switch for constant tolerance window"};
    Allen::Property<float> m_tolerance_window_x1_multiplier {this,
                                                             "tolerance_window_x1_multiplier",
                                                             1.f,
                                                             "constant value, at which defaut value is multiplied"};
    Allen::Property<float> m_tolerance_window_y1_multiplier {this,
                                                             "tolerance_window_y1_multiplier",
                                                             1.f,
                                                             "constant value, at which defaut value is multiplied"};
    Allen::Property<float> m_tolerance_window_x2_multiplier {this,
                                                             "tolerance_window_x2_multiplier",
                                                             1.f,
                                                             "constant value, at which defaut value is multiplied"};
    Allen::Property<float> m_tolerance_window_y2_multiplier {this,
                                                             "tolerance_window_y2_multiplier",
                                                             1.f,
                                                             "constant value, at which defaut value is multiplied"};
    Allen::Property<float> m_tolerance_window_x3_multiplier {this,
                                                             "tolerance_window_x3_multiplier",
                                                             1.f,
                                                             "constant value, at which defaut value is multiplied"};
    Allen::Property<float> m_tolerance_window_y3_multiplier {this,
                                                             "tolerance_window_y3_multiplier",
                                                             1.f,
                                                             "constant value, at which defaut value is multiplied"};
    Allen::Property<float> m_tolerance_window_x4_multiplier {this,
                                                             "tolerance_window_x4_multiplier",
                                                             1.f,
                                                             "constant value, at which defaut value is multiplied"};
    Allen::Property<float> m_tolerance_window_y4_multiplier {this,
                                                             "tolerance_window_y4_multiplier",
                                                             1.f,
                                                             "constant value, at which defaut value is multiplied"};

    TTrackSelector dev_ttrack_selector {"dev_ttrack_selector", "/HLT1Downstream/Hlt1_Downstream_TTrackSelector.json"};
  };

} // namespace downstream_find_hits
