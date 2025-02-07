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

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "SciFiEventModel.cuh"
#include "AlgorithmTypes.cuh"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "LookingForwardTools.cuh"
#include "KinUtils.cuh"
#include "SingleLayerFCNN.cuh"
#include "LFMomentumEstimation.cuh"

using LFQualityNN = Allen::MVAModels::SingleLayerFCNN<7, 32>;

namespace lf_quality_filter {

  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_input_tracks_t, unsigned) host_number_of_reconstructed_input_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_hit_offsets_t, unsigned) dev_scifi_hit_count;
    DEVICE_INPUT(dev_tracks_view_t, Allen::IMultiEventContainer*) dev_tracks_view;
    DEVICE_INPUT(dev_scifi_lf_length_filtered_tracks_t, SciFi::TrackHits) dev_scifi_lf_length_filtered_tracks;
    DEVICE_INPUT(dev_scifi_lf_length_filtered_atomics_t, unsigned) dev_scifi_lf_length_filtered_atomics;
    DEVICE_INPUT(dev_scifi_lf_parametrization_length_filter_t, float) dev_scifi_lf_parametrization_length_filter;
    DEVICE_INPUT(dev_input_states_t, MiniState) dev_input_states;
    DEVICE_OUTPUT(dev_lf_quality_of_tracks_t, float) dev_scifi_quality_of_tracks;
    DEVICE_OUTPUT(dev_offsets_long_tracks_t, unsigned) dev_offsets_long_tracks;
    HOST_OUTPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned)
    host_number_of_reconstructed_scifi_tracks;

    DEVICE_OUTPUT(dev_scifi_tracks_t, SciFi::TrackHits) dev_scifi_tracks;
    DEVICE_OUTPUT(dev_scifi_lf_y_parametrization_length_filter_t, float)
    dev_scifi_lf_y_parametrization_length_filter;
    DEVICE_OUTPUT(dev_scifi_lf_parametrization_consolidate_t, float) dev_scifi_lf_parametrization_consolidate;
  };

  __global__ void lf_quality_filter(
    Parameters,
    const LFQualityNN::DeviceType* dev_forward_ghost_killer,
    const LFQualityNN::DeviceType* dev_forward_no_ut_ghost_killer,
    const unsigned maximum_number_of_candidates_per_ut_track,
    const float max_diff_ty_window,
    const float factor_9_hits,
    const float factor_10_hits,
    const float factor_11_hits,
    const float factor_12_hits,
    const float max_final_quality,
    const float ghost_killer_threshold);

  struct lf_quality_filter_t : public DeviceAlgorithm, Parameters {

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {128, 1, 1}, "block dimensions"};
    Allen::Property<unsigned> m_maximum_number_of_candidates_per_ut_track {this,
                                                                           "maximum_number_of_candidates_per_ut_track",
                                                                           12,
                                                                           "maximum_number_of_candidates_per_ut_track"};
    Allen::Property<float> m_max_diff_ty_window {this, "max_diff_ty_window", 0.02, "max_diff_ty_window"};
    Allen::Property<float> m_max_final_quality {this, "max_final_quality", 0.5, "max_final_quality"};
    Allen::Property<float> m_factor_9_hits {this, "factor_9_hits", 5., "factor_9_hits"};
    Allen::Property<float> m_factor_10_hits {this, "factor_10_hits", 1., "factor_10_hits"};
    Allen::Property<float> m_factor_11_hits {this, "factor_11_hits", 0.8, "factor_11_hits"};
    Allen::Property<float> m_factor_12_hits {this, "factor_12_hits", 0.5, "factor_12_hits"};
    Allen::Property<float> m_ghost_killer_threshold {this, "ghost_killer_threshold", 0.5, "ghost_killer_threshold"};

    LFQualityNN forward_ghost_killer {"forward_ghost_killer", "/GhostProbability/Hlt1_LongGhostKiller_Forward.json"};
    LFQualityNN forward_ghost_killer_no_ut {"forward_ghost_killer_no_ut",
                                            "/GhostProbability/Hlt1_LongGhostKiller_noUT_Forward.json"};
  };
} // namespace lf_quality_filter
