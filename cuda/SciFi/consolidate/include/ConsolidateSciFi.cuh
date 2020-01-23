#pragma once

#include "SciFiEventModel.cuh"
#include "SciFiConsolidated.cuh"
#include "SciFiDefinitions.cuh"
#include "UTConsolidated.cuh"
#include "States.cuh"
#include "DeviceAlgorithm.cuh"
#include "LookingForwardConstants.cuh"

namespace scifi_consolidate_tracks {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_accumulated_number_of_hits_in_scifi_tracks_t, uint);
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, uint);
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_hit_offsets_t, uint) dev_scifi_hit_count;
    DEVICE_OUTPUT(dev_scifi_track_hits_t, char) dev_scifi_track_hits;
    DEVICE_INPUT(dev_offsets_forward_tracks_t, uint) dev_atomics_scifi;
    DEVICE_INPUT(dev_offsets_scifi_track_hit_number, uint) dev_scifi_track_hit_number;
    DEVICE_OUTPUT(dev_scifi_qop_t, float) dev_scifi_qop;
    DEVICE_OUTPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_OUTPUT(dev_scifi_track_ut_indices_t, uint) dev_scifi_track_ut_indices;
    DEVICE_INPUT(dev_offsets_ut_tracks_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, uint) dev_ut_track_hit_number;
    DEVICE_INPUT(dev_scifi_tracks_t, SciFi::TrackHits) dev_scifi_tracks;
    DEVICE_INPUT(dev_scifi_lf_parametrization_consolidate_t, float) dev_scifi_lf_parametrization_consolidate;
    PROPERTY(blockdim_t, DeviceDimensions, "block_dim", "block dimensions", {256, 1, 1});
  };

  __global__ void scifi_consolidate_tracks(Parameters);

  template<typename T, char... S>
  struct scifi_consolidate_tracks_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(scifi_consolidate_tracks)) function {scifi_consolidate_tracks};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_scifi_track_hits_t>(
        arguments, value<host_accumulated_number_of_hits_in_scifi_tracks_t>(arguments) * sizeof(SciFi::Hit));
      set_size<dev_scifi_qop_t>(arguments, value<host_number_of_reconstructed_scifi_tracks_t>(arguments));
      set_size<dev_scifi_track_ut_indices_t>(arguments, value<host_number_of_reconstructed_scifi_tracks_t>(arguments));
      set_size<dev_scifi_states_t>(arguments, value<host_number_of_reconstructed_scifi_tracks_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<blockdim_t>(), cuda_stream)(
        Parameters {begin<dev_scifi_hits_t>(arguments),
                    begin<dev_scifi_hit_offsets_t>(arguments),
                    begin<dev_scifi_track_hits_t>(arguments),
                    begin<dev_offsets_forward_tracks_t>(arguments),
                    begin<dev_offsets_scifi_track_hit_number>(arguments),
                    begin<dev_scifi_qop_t>(arguments),
                    begin<dev_scifi_states_t>(arguments),
                    begin<dev_scifi_track_ut_indices_t>(arguments),
                    begin<dev_offsets_ut_tracks_t>(arguments),
                    begin<dev_offsets_ut_track_hit_number_t>(arguments),
                    begin<dev_scifi_tracks_t>(arguments),
                    begin<dev_scifi_lf_parametrization_consolidate_t>(arguments)});

      // Transmission device to host of Scifi consolidated tracks
      if (runtime_options.do_check) {
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_atomics_scifi,
          begin<dev_offsets_forward_tracks_t>(arguments),
          size<dev_offsets_forward_tracks_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_scifi_track_hit_number,
          begin<dev_offsets_scifi_track_hit_number>(arguments),
          size<dev_offsets_scifi_track_hit_number>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_scifi_track_hits,
          begin<dev_scifi_track_hits_t>(arguments),
          size<dev_scifi_track_hits_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_scifi_qop,
          begin<dev_scifi_qop_t>(arguments),
          size<dev_scifi_qop_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_scifi_track_ut_indices,
          begin<dev_scifi_track_ut_indices_t>(arguments),
          size<dev_scifi_track_ut_indices_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
      }
    }

  private:
    Property<blockdim_t> m_blockdim {this};
  };
} // namespace scifi_consolidate_tracks
