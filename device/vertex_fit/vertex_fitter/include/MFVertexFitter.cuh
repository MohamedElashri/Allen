#pragma once

#include "VertexFitter.cuh"
#include "VertexDefinitions.cuh"
#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "DeviceAlgorithm.cuh"

namespace MFVertexFit {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, uint), host_number_of_selected_events),
    (HOST_INPUT(host_number_of_mf_svs_t, uint), host_number_of_mf_svs),
    (HOST_INPUT(host_selected_events_mf_t, uint), host_selected_events_mf),
    (DEVICE_INPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack), dev_kf_tracks),
    (DEVICE_INPUT(dev_mf_tracks_t, ParKalmanFilter::FittedTrack), dev_mf_tracks),
    (DEVICE_INPUT(dev_offsets_forward_tracks_t, uint), dev_offsets_forward_tracks),
    (DEVICE_INPUT(dev_mf_track_offsets_t, uint), dev_mf_track_offsets),
    (DEVICE_INPUT(dev_mf_sv_offsets_t, uint), dev_mf_sv_offsets),
    (DEVICE_INPUT(dev_svs_kf_idx_t, uint), dev_svs_kf_idx),
    (DEVICE_INPUT(dev_svs_mf_idx_t, uint), dev_svs_mf_idx),
    (DEVICE_INPUT(dev_event_list_mf_t, uint), dev_event_list_mf),
    (DEVICE_OUTPUT(dev_mf_svs_t, VertexFit::TrackMVAVertex), dev_mf_svs),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void fit_mf_vertices(Parameters);

  struct fit_mf_vertices_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{16, 16, 1}}};
  };

} // namespace MFVertexFit