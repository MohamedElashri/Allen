#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "UTConsolidated.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace lf_quality_filter_length {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, uint), host_number_of_selected_events),
    (HOST_INPUT(host_number_of_reconstructed_ut_tracks_t, uint), host_number_of_reconstructed_ut_tracks),
    (DEVICE_INPUT(dev_offsets_ut_tracks_t, uint), dev_atomics_ut),
    (DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, uint), dev_ut_track_hit_number),
    (DEVICE_INPUT(dev_scifi_lf_tracks_t, SciFi::TrackHits), dev_scifi_lf_tracks),
    (DEVICE_INPUT(dev_scifi_lf_atomics_t, uint), dev_scifi_lf_atomics),
    (DEVICE_OUTPUT(dev_scifi_lf_length_filtered_tracks_t, SciFi::TrackHits), dev_scifi_lf_length_filtered_tracks),
    (DEVICE_OUTPUT(dev_scifi_lf_length_filtered_atomics_t, uint), dev_scifi_lf_length_filtered_atomics),
    (DEVICE_INPUT(dev_scifi_lf_parametrization_t, float), dev_scifi_lf_parametrization),
    (DEVICE_OUTPUT(dev_scifi_lf_parametrization_length_filter_t, float), dev_scifi_lf_parametrization_length_filter),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void lf_quality_filter_length(Parameters);

  struct lf_quality_filter_length_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace lf_quality_filter_length
