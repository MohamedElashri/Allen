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
#include "AllenMonitoring.h"

namespace lf_triplet_seeding {
  struct Parameters {
    Allen::KernelInvocationConfiguration config;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_input_tracks_t, unsigned) host_number_of_reconstructed_input_tracks;
    HOST_INPUT(host_scifi_hit_count_t, unsigned) host_scifi_hit_count;
    HOST_INPUT(host_track_type_id_t, Allen::TypeIDs) host_track_type_id;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_hit_offsets_t, unsigned) dev_scifi_hit_count;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    DEVICE_INPUT(dev_tracks_view_t, Allen::IMultiEventContainer*) dev_tracks_view;
    DEVICE_INPUT(dev_scifi_lf_initial_windows_t, int) dev_scifi_lf_initial_windows;
    DEVICE_INPUT(dev_input_states_t, MiniState) dev_input_states;
    DEVICE_INPUT(dev_scifi_lf_number_of_tracks_t, unsigned) dev_scifi_lf_number_of_tracks;
    DEVICE_INPUT(dev_scifi_lf_tracks_indices_t, unsigned) dev_scifi_lf_tracks_indices;
    DEVICE_OUTPUT(dev_scifi_lf_found_triplets_t, SciFi::lf_triplet::t) dev_scifi_lf_found_triplets;
    DEVICE_OUTPUT(dev_scifi_lf_number_of_found_triplets_t, unsigned) dev_scifi_lf_number_of_found_triplets;
    DEVICE_OUTPUT(dev_global_xs_t, half_t) dev_global_xs;
    DEVICE_OUTPUT(dev_global_count_t, unsigned) dev_global_count;
  };

  __global__ void lf_triplet_seeding(
    Parameters,
    const LookingForward::Constants* dev_looking_forward_constants,
    const unsigned maximum_number_of_triplets_per_warp,
    const float chi2_max_triplet_single,
    const float z_mag_difference,
    Allen::Monitoring::Counter<>::DeviceType);

  struct lf_triplet_seeding_t : public DeviceAlgorithm, Parameters {

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<unsigned> m_maximum_number_of_triplets_per_warp {this,
                                                                     "maximum_number_of_triplets_per_warp",
                                                                     LookingForward::max_triplets_per_track,
                                                                     "maximum_number_of_triplets_per_warp"};
    Allen::Property<float> m_chi2_max_triplet_single {this, "chi2_max_triplet_single", 8., "chi2_max_triplet_single"};
    Allen::Property<float> m_z_mag_difference {this, "z_mag_difference", 10., "z_mag_difference"};
    Allen::Monitoring::Counter<> m_n_overflow_maximum_number_of_triplets_per_warp {
      this,
      "n_overflow_maximum_number_of_triplets_per_warp"};
  };
} // namespace lf_triplet_seeding
