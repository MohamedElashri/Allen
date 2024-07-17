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
#include "NeuralNetwork.cuh"
#include "LFMomentumEstimation.cuh"

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
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
    PROPERTY(
      maximum_number_of_candidates_per_ut_track_t,
      "maximum_number_of_candidates_per_ut_track",
      "maximum_number_of_candidates_per_ut_track",
      unsigned)
    maximum_number_of_candidates_per_ut_track;
    PROPERTY(max_diff_ty_window_t, "max_diff_ty_window", "max_diff_ty_window", float) max_diff_ty_window;
    PROPERTY(max_final_quality_t, "max_final_quality", "max_final_quality", float) max_final_quality;
    PROPERTY(factor_9_hits_t, "factor_9_hits", "factor_9_hits", float) factor_9_hits;
    PROPERTY(factor_10_hits_t, "factor_10_hits", "factor_10_hits", float) factor_10_hits;
    PROPERTY(factor_11_hits_t, "factor_11_hits", "factor_11_hits", float) factor_11_hits;
    PROPERTY(factor_12_hits_t, "factor_12_hits", "factor_12_hits", float) factor_12_hits;
    PROPERTY(ghost_killer_threshold_t, "ghost_killer_threshold", "ghost_killer_threshold", float)
    ghost_killer_threshold;
  };

  __global__ void lf_quality_filter(
    Parameters,
    const Allen::NeuralNetwork::Model::ForwardGhostKiller* dev_forward_ghost_killer,
    const Allen::NeuralNetwork::Model::ForwardGhostKiller* dev_forward_no_ut_ghost_killer);

  struct lf_quality_filter_t : public DeviceAlgorithm, Parameters {

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{128, 1, 1}}};
    Property<maximum_number_of_candidates_per_ut_track_t> m_maximum_number_of_candidates_per_ut_track {this, 12};
    Property<max_diff_ty_window_t> m_max_diff_ty_window {this, 0.02};
    Property<max_final_quality_t> m_max_final_quality {this, 0.5};
    Property<factor_9_hits_t> m_factor_9_hits {this, 5.};
    Property<factor_10_hits_t> m_factor_10_hits {this, 1.};
    Property<factor_11_hits_t> m_factor_11_hits {this, 0.8};
    Property<factor_12_hits_t> m_factor_12_hits {this, 0.5};
    Property<ghost_killer_threshold_t> m_ghost_killer_threshold {this, 0.5};
  };
} // namespace lf_quality_filter
