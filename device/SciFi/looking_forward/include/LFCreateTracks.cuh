/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
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
    PROPERTY(
      calculate_parametrization_block_dim_t,
      "calculate_parametrization_block_dim",
      "block dimensions calculate parametrization",
      DeviceDimensions)
    calculate_parametrization_block_dim;
    PROPERTY(extend_tracks_block_dim_t, "extend_tracks_block_dim", "block dimensions extend tracks", DeviceDimensions)
    extend_tracks_block_dim;
    PROPERTY(
      chi2_max_extrapolation_to_x_layers_single_t,
      "chi2_max_extrapolation_to_x_layers_single",
      "chi2_max_extrapolation_to_x_layers_single",
      float)
    chi2_max_extrapolation_to_x_layers_single;
    PROPERTY(max_triplets_per_input_track_t, "max_triplets_per_input_track", "max_triplets_per_input_track", unsigned)
    max_triplets_per_input_track;
    PROPERTY(
      maximum_number_of_triplets_per_warp_t,
      "maximum_number_of_triplets_per_warp",
      "maximum_number_of_triplets_per_warp",
      unsigned)
    maximum_number_of_triplets_per_warp;
    PROPERTY(uv_hits_chi2_factor_t, "uv_hits_chi2_factor", "uv_hits_chi2_factor", float) uv_hits_chi2_factor;
  };

  __global__ void lf_triplet_keep_best(Parameters, const LookingForward::Constants* dev_looking_forward_constants);

  __global__ void lf_calculate_parametrization(
    Parameters,
    const LookingForward::Constants* dev_looking_forward_constants);

  __global__ void lf_extend_tracks(Parameters, const LookingForward::Constants* dev_looking_forward_constants);

  struct lf_create_tracks_t : public DeviceAlgorithm, Parameters {
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
      const Allen::Context& context) const;

  private:
    Property<calculate_parametrization_block_dim_t> m_calculate_parametrization_block_dim {this, {{128, 1, 1}}};
    Property<extend_tracks_block_dim_t> m_extend_tracks_block_dim {this, {{256, 1, 1}}};
    Property<max_triplets_per_input_track_t> m_max_triplets_per_input_track {this, 12};
    Property<maximum_number_of_triplets_per_warp_t> m_maximum_number_of_triplets_per_warp {this, 64};
    Property<chi2_max_extrapolation_to_x_layers_single_t> m_chi2_max_extrapolation_to_x_layers_single {this, 2.};
    Property<uv_hits_chi2_factor_t> m_uv_hits_chi2_factor {this, 50.};
  };
} // namespace lf_create_tracks
