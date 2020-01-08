#pragma once

#include "VeloEventModel.cuh"
#include "UTDefinitions.cuh"
#include "UTEventModel.cuh"
#include "UTConsolidated.cuh"
#include "DeviceAlgorithm.cuh"

namespace ut_copy_track_hit_number {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events, uint);
    HOST_INPUT(host_number_of_reconstructed_ut_tracks_t, uint);
    DEVICE_INPUT(dev_ut_tracks_t, UT::TrackHits) dev_ut_tracks;
    DEVICE_INPUT(dev_atomics_ut_t, uint) dev_atomics_ut;
    DEVICE_OUTPUT(dev_ut_track_hit_number_t, uint) dev_ut_track_hit_number;
  };

  __global__ void ut_copy_track_hit_number(Parameters);

  template<typename T>
  struct ut_copy_track_hit_number_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name {"ut_copy_track_hit_number_t"};
    decltype(global_function(ut_copy_track_hit_number)) function {ut_copy_track_hit_number};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_ut_track_hit_number_t>(arguments, value<host_number_of_reconstructed_ut_tracks_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      function(dim3(value<host_number_of_selected_events>(arguments)), block_dimension(), cuda_stream)(
        Parameters {offset<dev_ut_tracks_t>(arguments),
                   offset<dev_atomics_ut_t>(arguments),
                   offset<dev_ut_track_hit_number_t>(arguments)});
    }
  };
} // namespace ut_copy_track_hit_number