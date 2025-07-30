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

#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "SciFiEventModel.cuh"
#include "SciFiDefinitions.cuh"
#include "AlgorithmTypes.cuh"
#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"

namespace lf_create_tracks {
  struct Parameters {
    Allen::KernelInvocationConfiguration config;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_input_tracks_t, unsigned) host_number_of_reconstructed_input_tracks;
    HOST_INPUT(host_track_type_id_t, Allen::TypeIDs) host_track_type_id;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_scifi_lf_initial_windows_t, int) dev_scifi_lf_initial_windows;
    DEVICE_INPUT(dev_scifi_lf_number_of_tracks_t, unsigned) dev_scifi_lf_number_of_tracks;
    DEVICE_INPUT(dev_scifi_lf_tracks_indices_t, unsigned) dev_scifi_lf_tracks_indices;
    DEVICE_INPUT(dev_scifi_lf_found_triplets_t, SciFi::lf_triplet::t) dev_scifi_lf_found_triplets;
    DEVICE_INPUT(dev_scifi_lf_number_of_found_triplets_t, unsigned) dev_scifi_lf_number_of_found_triplets;
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_hit_offsets_t, unsigned) dev_scifi_hit_count;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    DEVICE_INPUT(dev_tracks_view_t, Allen::IMultiEventContainer*) dev_tracks_view;
    DEVICE_INPUT(dev_input_states_t, MiniState) dev_input_states;
    DEVICE_OUTPUT(dev_scifi_lf_tracks_t, SciFi::TrackHits) dev_scifi_lf_tracks;
    DEVICE_OUTPUT(dev_scifi_lf_atomics_t, unsigned) dev_scifi_lf_atomics;
    DEVICE_OUTPUT(dev_scifi_lf_total_number_of_found_triplets_t, unsigned)
    dev_scifi_lf_total_number_of_found_triplets;
    DEVICE_OUTPUT(dev_scifi_lf_parametrization_t, float) dev_scifi_lf_parametrization;
  };

  __global__ void lf_triplet_keep_best(
    Parameters,
    const LookingForward::Constants* dev_looking_forward_constants,
    const unsigned max_triplets_per_input_track,
    const unsigned maximum_number_of_triplets_per_warp);

  __global__ void lf_calculate_parametrization(Parameters, const unsigned max_triplets_per_input_track);

  __global__ void lf_extend_tracks(
    Parameters,
    const LookingForward::Constants* dev_looking_forward_constants,
    const unsigned max_triplets_per_input_track,
    const float uv_hits_chi2_factor_y,
    const float uv_hits_chi2_factor_x,
    const float chi2_max_extrapolation_to_x_layers_single);

  struct lf_create_tracks_t : public DeviceAlgorithm, Parameters {

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_calculate_parametrization_block_dim {this,
                                                                 "calculate_parametrization_block_dim",
                                                                 {128, 1, 1},
                                                                 "block dimensions calculate parametrization"};
    Allen::Property<dim3> m_extend_tracks_block_dim {this,
                                                     "extend_tracks_block_dim",
                                                     {256, 1, 1},
                                                     "block dimensions extend tracks"};
    Allen::Property<unsigned> m_max_triplets_per_input_track {this,
                                                              "max_triplets_per_input_track",
                                                              12,
                                                              "max_triplets_per_input_track"};
    Allen::Property<unsigned> m_maximum_number_of_triplets_per_warp {this,
                                                                     "maximum_number_of_triplets_per_warp",
                                                                     LookingForward::max_triplets_per_track,
                                                                     "maximum_number_of_triplets_per_warp"};
    Allen::Property<float> m_chi2_max_extrapolation_to_x_layers_single {this,
                                                                        "chi2_max_extrapolation_to_x_layers_single",
                                                                        2.,
                                                                        "chi2_max_extrapolation_to_x_layers_single"};
    Allen::Property<float> m_uv_hits_chi2_factor_x {this, "uv_hits_chi2_factor_x", 50., "uv_hits_chi2_factor_x"};
    Allen::Property<float> m_uv_hits_chi2_factor_y {this, "uv_hits_chi2_factor_y", 50., "uv_hits_chi2_factor_y"};
  };
} // namespace lf_create_tracks
