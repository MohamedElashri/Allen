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
#include "TypeID.h"

namespace lf_search_initial_windows {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_input_tracks_t, unsigned) host_number_of_reconstructed_input_tracks;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_hit_offsets_t, unsigned) dev_scifi_hit_offsets;
    DEVICE_INPUT(dev_tracks_view_t, Allen::IMultiEventContainer*) dev_tracks_view;
    HOST_INPUT(host_track_type_id_t, Allen::TypeIDs) host_track_type_id;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    DEVICE_INPUT(dev_ut_selected_velo_tracks_offsets_t, unsigned) dev_ut_selected_velo_tracks_offsets;
    DEVICE_INPUT(dev_ut_selected_velo_tracks_t, unsigned) dev_ut_selected_velo_tracks;
    DEVICE_OUTPUT(dev_scifi_lf_initial_windows_t, int) dev_scifi_lf_initial_windows;
    DEVICE_OUTPUT(dev_input_states_t, MiniState) dev_input_states;
    DEVICE_OUTPUT(dev_scifi_lf_number_of_tracks_t, unsigned) dev_scifi_lf_number_of_tracks;
    DEVICE_OUTPUT(dev_scifi_lf_tracks_indices_t, unsigned) dev_scifi_lf_tracks_indices;
  };

  __global__ void lf_search_initial_windows(
    Parameters,
    const LookingForward::Constants* dev_looking_forward_constants,
    const float* dev_magnet_polarity,
    const float input_pt,
    const float input_momentum,
    const int hit_window_size,
    const float initial_windows_max_offset_uv_window,
    const float x_windows_factor,
    const float overlap_in_mm);

  struct lf_search_initial_windows_t : public DeviceAlgorithm, Parameters {
    void update(const Constants& constants) const;

    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};
    Allen::Property<unsigned> m_hit_window_size {this, "hit_window_size", 32, "maximum hit window size"};
    Allen::Property<float> m_input_momentum {this, "input_momentum", 5000., "momentum assumption to open SW"};
    Allen::Property<float> m_input_pt {this, "input_pt", 1000., "pt assumption to open SW"};
    Allen::Property<float> m_overlap_in_mm {this, "overlap_in_mm", 50., "overlap between SWs left-right"};
    Allen::Property<float> m_initial_windows_max_offset_uv_window {this,
                                                                   "initial_windows_max_offset_uv_window",
                                                                   800.,
                                                                   "initial_windows_max_offset_uv_window"};
    Allen::Property<float> m_x_windows_factor {this, "x_windows_factor", 1., "x_windows_factor"};
  };
} // namespace lf_search_initial_windows
