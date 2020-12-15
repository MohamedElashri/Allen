/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "LookingForwardTools.cuh"

namespace lf_quality_filter {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (HOST_INPUT(host_number_of_reconstructed_ut_tracks_t, unsigned), host_number_of_reconstructed_ut_tracks),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_number_of_events_t, unsigned), dev_number_of_events),
    (DEVICE_INPUT(dev_scifi_hits_t, char), dev_scifi_hits),
    (DEVICE_INPUT(dev_scifi_hit_offsets_t, unsigned), dev_scifi_hit_count),
    (DEVICE_INPUT(dev_offsets_ut_tracks_t, unsigned), dev_atomics_ut),
    (DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, unsigned), dev_ut_track_hit_number),
    (DEVICE_INPUT(dev_scifi_lf_length_filtered_tracks_t, SciFi::TrackHits), dev_scifi_lf_length_filtered_tracks),
    (DEVICE_INPUT(dev_scifi_lf_length_filtered_atomics_t, unsigned), dev_scifi_lf_length_filtered_atomics),
    (DEVICE_INPUT(dev_scifi_lf_parametrization_length_filter_t, float), dev_scifi_lf_parametrization_length_filter),
    (DEVICE_INPUT(dev_ut_states_t, MiniState), dev_ut_states),
    (DEVICE_INPUT(dev_ut_track_velo_indices_t, unsigned), dev_ut_track_velo_indices),
    (DEVICE_OUTPUT(dev_lf_quality_of_tracks_t, float), dev_scifi_quality_of_tracks),
    (DEVICE_OUTPUT(dev_atomics_scifi_t, unsigned), dev_atomics_scifi),
    (DEVICE_OUTPUT(dev_scifi_tracks_t, SciFi::TrackHits), dev_scifi_tracks),
    (DEVICE_OUTPUT(dev_scifi_lf_y_parametrization_length_filter_t, float),
     dev_scifi_lf_y_parametrization_length_filter),
    (DEVICE_OUTPUT(dev_scifi_lf_parametrization_consolidate_t, float), dev_scifi_lf_parametrization_consolidate),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void lf_quality_filter(
    Parameters,
    const LookingForward::Constants* dev_looking_forward_constants);

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
      cudaStream_t& stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{128, 1, 1}}};
  };
} // namespace lf_quality_filter
