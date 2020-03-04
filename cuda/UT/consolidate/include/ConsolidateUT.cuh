#pragma once

#include "UTDefinitions.cuh"
#include "UTEventModel.cuh"
#include "UTConsolidated.cuh"
#include "DeviceAlgorithm.cuh"

namespace ut_consolidate_tracks {
  struct Parameters {
    HOST_INPUT(host_accumulated_number_of_ut_hits_t, uint);
    HOST_INPUT(host_number_of_reconstructed_ut_tracks_t, uint);
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_accumulated_number_of_hits_in_ut_tracks_t, uint);
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, uint) dev_ut_hit_offsets;
    DEVICE_OUTPUT(dev_ut_track_hits_t, char) dev_ut_track_hits;
    DEVICE_INPUT(dev_offsets_ut_tracks_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, uint) dev_ut_track_hit_number;
    DEVICE_OUTPUT(dev_ut_qop_t, float) dev_ut_qop;
    DEVICE_OUTPUT(dev_ut_x_t, float) dev_ut_x;
    DEVICE_OUTPUT(dev_ut_tx_t, float) dev_ut_tx;
    DEVICE_OUTPUT(dev_ut_z_t, float) dev_ut_z;
    DEVICE_OUTPUT(dev_ut_track_velo_indices_t, uint) dev_ut_track_velo_indices;
    DEVICE_INPUT(dev_ut_tracks_t, UT::TrackHits) dev_ut_tracks;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

  __global__ void ut_consolidate_tracks(Parameters, const uint* dev_unique_x_sector_layer_offsets);

  template<typename T, char... S>
  struct ut_consolidate_tracks_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(ut_consolidate_tracks)) function {ut_consolidate_tracks};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_ut_track_hits_t>(
        arguments,
        value<host_accumulated_number_of_ut_hits_t>(arguments) * UT::Consolidated::hits_number_of_arrays *
          sizeof(uint32_t));
      set_size<dev_ut_qop_t>(arguments, value<host_number_of_reconstructed_ut_tracks_t>(arguments));
      set_size<dev_ut_track_velo_indices_t>(arguments, value<host_number_of_reconstructed_ut_tracks_t>(arguments));
      set_size<dev_ut_x_t>(arguments, value<host_number_of_reconstructed_ut_tracks_t>(arguments));
      set_size<dev_ut_z_t>(arguments, value<host_number_of_reconstructed_ut_tracks_t>(arguments));
      set_size<dev_ut_tx_t>(arguments, value<host_number_of_reconstructed_ut_tracks_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_ut_hits_t>(arguments),
                    begin<dev_ut_hit_offsets_t>(arguments),
                    begin<dev_ut_track_hits_t>(arguments),
                    begin<dev_offsets_ut_tracks_t>(arguments),
                    begin<dev_offsets_ut_track_hit_number_t>(arguments),
                    begin<dev_ut_qop_t>(arguments),
                    begin<dev_ut_x_t>(arguments),
                    begin<dev_ut_tx_t>(arguments),
                    begin<dev_ut_z_t>(arguments),
                    begin<dev_ut_track_velo_indices_t>(arguments),
                    begin<dev_ut_tracks_t>(arguments)},
        constants.dev_unique_x_sector_layer_offsets.data());

      if (runtime_options.do_check) {
        // Transmission device to host of UT consolidated tracks
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_atomics_ut,
          begin<dev_offsets_ut_tracks_t>(arguments),
          size<dev_offsets_ut_tracks_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_ut_track_hit_number,
          begin<dev_offsets_ut_track_hit_number_t>(arguments),
          size<dev_offsets_ut_track_hit_number_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_ut_track_hits,
          begin<dev_ut_track_hits_t>(arguments),
          size<dev_ut_track_hits_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_ut_qop,
          begin<dev_ut_qop_t>(arguments),
          size<dev_ut_qop_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_ut_x,
          begin<dev_ut_x_t>(arguments),
          size<dev_ut_x_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_ut_tx,
          begin<dev_ut_tx_t>(arguments),
          size<dev_ut_tx_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_ut_z,
          begin<dev_ut_z_t>(arguments),
          size<dev_ut_z_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_ut_track_velo_indices,
          begin<dev_ut_track_velo_indices_t>(arguments),
          size<dev_ut_track_velo_indices_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
      }
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace ut_consolidate_tracks