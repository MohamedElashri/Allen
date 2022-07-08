/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "SciFiEventModel.cuh"
#include "AlgorithmTypes.cuh"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "LookingForwardTools.cuh"

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
    DEVICE_OUTPUT(dev_atomics_scifi_t, unsigned) dev_atomics_scifi;
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
  };

  __global__ void lf_quality_filter(Parameters, const LookingForward::Constants* dev_looking_forward_constants);

  struct lf_quality_filter_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{128, 1, 1}}};
    Property<maximum_number_of_candidates_per_ut_track_t> m_maximum_number_of_candidates_per_ut_track {this, 12};
    Property<max_diff_ty_window_t> m_max_diff_ty_window {this, 0.02};
  };
} // namespace lf_quality_filter
