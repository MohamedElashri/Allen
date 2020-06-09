#pragma once

#include "SciFiEventModel.cuh"
#include "SciFiConsolidated.cuh"
#include "SciFiDefinitions.cuh"
#include "UTConsolidated.cuh"
#include "States.cuh"
#include "DeviceAlgorithm.cuh"
#include "LookingForwardConstants.cuh"

namespace scifi_consolidate_tracks {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, uint), host_number_of_selected_events),
    (HOST_INPUT(host_accumulated_number_of_hits_in_scifi_tracks_t, uint), host_accumulated_number_of_hits_in_scifi_tracks),
    (HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, uint), host_number_of_reconstructed_scifi_tracks),
    (DEVICE_INPUT(dev_scifi_hits_t, char), dev_scifi_hits),
    (DEVICE_INPUT(dev_scifi_hit_offsets_t, uint), dev_scifi_hit_count),
    (DEVICE_OUTPUT(dev_scifi_track_hits_t, char), dev_scifi_track_hits),
    (DEVICE_INPUT(dev_offsets_forward_tracks_t, uint), dev_atomics_scifi),
    (DEVICE_INPUT(dev_offsets_scifi_track_hit_number_t, uint), dev_scifi_track_hit_number),
    (DEVICE_OUTPUT(dev_scifi_qop_t, float), dev_scifi_qop),
    (DEVICE_OUTPUT(dev_scifi_states_t, MiniState), dev_scifi_states),
    (DEVICE_OUTPUT(dev_scifi_track_ut_indices_t, uint), dev_scifi_track_ut_indices),
    (DEVICE_INPUT(dev_offsets_ut_tracks_t, uint), dev_atomics_ut),
    (DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, uint), dev_ut_track_hit_number),
    (DEVICE_INPUT(dev_scifi_tracks_t, SciFi::TrackHits), dev_scifi_tracks),
    (DEVICE_INPUT(dev_scifi_lf_parametrization_consolidate_t, float), dev_scifi_lf_parametrization_consolidate),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void scifi_consolidate_tracks(Parameters);

  struct scifi_consolidate_tracks_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace scifi_consolidate_tracks
