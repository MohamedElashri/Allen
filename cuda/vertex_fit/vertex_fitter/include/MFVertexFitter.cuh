#pragma once

#include "VertexFitter.cuh"
#include "VertexDefinitions.cuh"
#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "DeviceAlgorithm.cuh"

namespace MFVertexFit {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_mf_svs_t, uint);
    HOST_INPUT(host_selected_events_mf_t, uint);
    DEVICE_INPUT(dev_kf_tracks_t, ParKalmanFilter::FittedTrack) dev_kf_tracks;
    DEVICE_INPUT(dev_mf_tracks_t, ParKalmanFilter::FittedTrack) dev_mf_tracks;
    DEVICE_INPUT(dev_offsets_forward_tracks_t, uint) dev_offsets_forward_tracks;
    DEVICE_INPUT(dev_mf_track_offsets_t, uint) dev_mf_track_offsets;
    DEVICE_INPUT(dev_mf_sv_offsets_t, uint) dev_mf_sv_offsets;
    DEVICE_INPUT(dev_svs_kf_idx_t, uint) dev_svs_kf_idx;
    DEVICE_INPUT(dev_svs_mf_idx_t, uint) dev_svs_mf_idx;
    DEVICE_INPUT(dev_event_list_mf_t, uint) dev_event_list_mf;
    DEVICE_OUTPUT(dev_mf_svs_t, VertexFit::TrackMVAVertex) dev_mf_svs;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {16, 16, 1});
  };

  __global__ void fit_mf_vertices(Parameters);

  template<typename T, char... S>
  struct fit_mf_vertices_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(fit_mf_vertices)) function {fit_mf_vertices};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_mf_svs_t>(arguments, value<host_number_of_mf_svs_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      function(dim3(value<host_selected_events_mf_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_kf_tracks_t>(arguments),
                    begin<dev_mf_tracks_t>(arguments),
                    begin<dev_offsets_forward_tracks_t>(arguments),
                    begin<dev_mf_track_offsets_t>(arguments),
                    begin<dev_mf_sv_offsets_t>(arguments),
                    begin<dev_svs_kf_idx_t>(arguments),
                    begin<dev_svs_mf_idx_t>(arguments),
                    begin<dev_event_list_mf_t>(arguments),
                    begin<dev_mf_svs_t>(arguments)});

      cudaCheck(cudaMemcpyAsync(
        host_buffers.host_mf_secondary_vertices,
        begin<dev_mf_svs_t>(arguments),
        size<dev_mf_svs_t>(arguments),
        cudaMemcpyDeviceToHost,
        cuda_stream));
      cudaCheck(cudaMemcpyAsync(
        host_buffers.host_mf_sv_offsets,
        begin<dev_mf_sv_offsets_t>(arguments),
        size<dev_mf_sv_offsets_t>(arguments),
        cudaMemcpyDeviceToHost,
        cuda_stream));
    }

  private:
    Property<block_dim_t> m_block_dim {this};
  };

} // namespace MFVertexFit