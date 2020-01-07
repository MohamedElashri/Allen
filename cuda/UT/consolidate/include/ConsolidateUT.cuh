#pragma once

#include "UTDefinitions.cuh"
#include "UTEventModel.cuh"
#include "UTConsolidated.cuh"
#include "DeviceAlgorithm.cuh"

namespace ut_consolidate_tracks {
  struct Arguments {
    HOST_INPUT(host_accumulated_number_of_ut_hits_t, uint);
    HOST_INPUT(host_number_of_reconstructed_ut_tracks_t, uint);
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_accumulated_number_of_hits_in_ut_tracks_t, uint);
    DEVICE_INPUT(dev_ut_hits_t, uint) dev_ut_hits;
    DEVICE_INPUT(dev_ut_hit_offsets_t, uint) dev_ut_hit_offsets;
    DEVICE_OUTPUT(dev_ut_track_hits_t, char) dev_ut_track_hits;
    DEVICE_INPUT(dev_atomics_ut_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_ut_track_hit_number_t, uint) dev_ut_track_hit_number;
    DEVICE_OUTPUT(dev_ut_qop_t, float) dev_ut_qop;
    DEVICE_OUTPUT(dev_ut_x_t, float) dev_ut_x;
    DEVICE_OUTPUT(dev_ut_tx_t, float) dev_ut_tx;
    DEVICE_OUTPUT(dev_ut_z_t, float) dev_ut_z;
    DEVICE_OUTPUT(dev_ut_track_velo_indices_t, uint) dev_ut_track_velo_indices;
    DEVICE_INPUT(dev_ut_tracks_t, UT::TrackHits) dev_ut_tracks;
  };

  __global__ void ut_consolidate_tracks(Arguments, const uint* dev_unique_x_sector_layer_offsets);

  template<typename T>
  struct ut_consolidate_tracks_t : public DeviceAlgorithm, Arguments {
    constexpr static auto name {"ut_consolidate_tracks_t"};
    decltype(global_function(ut_consolidate_tracks)) function {ut_consolidate_tracks};

    void set_arguments_size(
      ArgumentRefManager<T> manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_ut_track_hits_t>(manager, value<host_accumulated_number_of_ut_hits_t>(manager) * sizeof(UT::Hit));
      set_size<dev_ut_qop_t>(manager, value<host_number_of_reconstructed_ut_tracks_t>(manager));
      set_size<dev_ut_track_velo_indices_t>(manager, value<host_number_of_reconstructed_ut_tracks_t>(manager));
      set_size<dev_ut_x_t>(manager, value<host_number_of_reconstructed_ut_tracks_t>(manager));
      set_size<dev_ut_z_t>(manager, value<host_number_of_reconstructed_ut_tracks_t>(manager));
      set_size<dev_ut_tx_t>(manager, value<host_number_of_reconstructed_ut_tracks_t>(manager));
    }

    void operator()(
      const ArgumentRefManager<T>& manager,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      function.invoke(dim3(value<host_number_of_selected_events_t>(manager)), block_dimension(), cuda_stream)(
        Arguments {offset<dev_ut_hits_t>(manager),
                   offset<dev_ut_hit_offsets_t>(manager),
                   offset<dev_ut_track_hits_t>(manager),
                   offset<dev_atomics_ut_t>(manager),
                   offset<dev_ut_track_hit_number_t>(manager),
                   offset<dev_ut_qop_t>(manager),
                   offset<dev_ut_x_t>(manager),
                   offset<dev_ut_tx_t>(manager),
                   offset<dev_ut_z_t>(manager),
                   offset<dev_ut_track_velo_indices_t>(manager),
                   offset<dev_ut_tracks_t>(manager)},
        constants.dev_unique_x_sector_layer_offsets.data());

      if (runtime_options.do_check) {
        // Transmission device to host of UT consolidated tracks
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_atomics_ut,
          offset<dev_atomics_ut_t>(manager),
          (2 * value<host_number_of_selected_events_t>(manager) + 1) * sizeof(uint),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_ut_track_hit_number,
          offset<dev_ut_track_hit_number_t>(manager),
          size<dev_ut_track_hit_number_t>(manager),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_ut_track_hits,
          offset<dev_ut_track_hits_t>(manager),
          value<host_accumulated_number_of_hits_in_ut_tracks_t>(manager) * sizeof(UT::Hit),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_ut_qop,
          offset<dev_ut_qop_t>(manager),
          size<dev_ut_qop_t>(manager),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_ut_x,
          offset<dev_ut_x_t>(manager),
          size<dev_ut_x_t>(manager),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_ut_tx,
          offset<dev_ut_tx_t>(manager),
          size<dev_ut_tx_t>(manager),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_ut_z,
          offset<dev_ut_z_t>(manager),
          size<dev_ut_z_t>(manager),
          cudaMemcpyDeviceToHost,
          cuda_stream));

        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_ut_track_velo_indices,
          offset<dev_ut_track_velo_indices_t>(manager),
          size<dev_ut_track_velo_indices_t>(manager),
          cudaMemcpyDeviceToHost,
          cuda_stream));
      }
    }
  };
} // namespace ut_consolidate_tracks