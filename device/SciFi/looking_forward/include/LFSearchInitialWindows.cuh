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
    DEVICE_INPUT(dev_ut_number_of_selected_velo_tracks_t, unsigned) dev_ut_number_of_selected_velo_tracks;
    DEVICE_INPUT(dev_ut_selected_velo_tracks_t, unsigned) dev_ut_selected_velo_tracks;
    DEVICE_OUTPUT(dev_scifi_lf_initial_windows_t, int) dev_scifi_lf_initial_windows;
    DEVICE_OUTPUT(dev_input_states_t, MiniState) dev_input_states;
    DEVICE_OUTPUT(dev_scifi_lf_number_of_tracks_t, unsigned) dev_scifi_lf_number_of_tracks;
    DEVICE_OUTPUT(dev_scifi_lf_tracks_indices_t, unsigned) dev_scifi_lf_tracks_indices;
    PROPERTY(hit_window_size_t, "hit_window_size", "maximum hit window size", unsigned) hit_window_size;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions);
    PROPERTY(input_momentum_t, "input_momentum", "momentum assumption to open SW", float) input_momentum;
    PROPERTY(input_pt_t, "input_pt", "pt assumption to open SW", float) input_pt;
    PROPERTY(overlap_in_mm_t, "overlap_in_mm", "overlap between SWs left-right", float) overlap_in_mm;
    PROPERTY(
      initial_windows_max_offset_uv_window_t,
      "initial_windows_max_offset_uv_window",
      "initial_windows_max_offset_uv_window",
      float)
    initial_windows_max_offset_uv_window;
    PROPERTY(x_windows_factor_t, "x_windows_factor", "x_windows_factor", float) x_windows_factor;
  };

  __global__ void lf_search_initial_windows(
    Parameters,
    const char* dev_scifi_geometry,
    const LookingForward::Constants* dev_looking_forward_constants,
    const float* dev_magnet_polarity);

  struct lf_search_initial_windows_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
    Property<hit_window_size_t> m_hit_window_size {this, 32};
    Property<input_momentum_t> m_input_momentum {this, 5000.};
    Property<input_pt_t> m_input_pt {this, 1000.};
    Property<overlap_in_mm_t> m_overlap_in_mm {this, 50.};
    Property<initial_windows_max_offset_uv_window_t> m_initial_windows_max_offset_uv_window {this, 800.};
    Property<x_windows_factor_t> m_x_windows_factor {this, 1.};
  };
} // namespace lf_search_initial_windows
