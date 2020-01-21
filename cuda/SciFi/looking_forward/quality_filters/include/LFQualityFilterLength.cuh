#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "UTConsolidated.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace lf_quality_filter_length {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_ut_tracks_t, uint);
    DEVICE_INPUT(dev_offsets_ut_tracks_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, uint) dev_ut_track_hit_number;
    DEVICE_OUTPUT(dev_scifi_lf_tracks_t, SciFi::TrackHits) dev_scifi_lf_tracks;
    DEVICE_INPUT(dev_scifi_lf_atomics_t, uint) dev_scifi_lf_atomics;
    DEVICE_OUTPUT(dev_scifi_lf_length_filtered_tracks_t, SciFi::TrackHits) dev_scifi_lf_length_filtered_tracks;
    DEVICE_OUTPUT(dev_scifi_lf_length_filtered_atomics_t, uint) dev_scifi_lf_length_filtered_atomics;
    DEVICE_INPUT(dev_scifi_lf_parametrization_t, float) dev_scifi_lf_parametrization;
    DEVICE_OUTPUT(dev_scifi_lf_parametrization_length_filter_t, float) dev_scifi_lf_parametrization_length_filter;
  };

  __global__ void lf_quality_filter_length(Parameters);

  template<typename T, char... S>
  struct lf_quality_filter_length_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(lf_quality_filter_length)) function {lf_quality_filter_length};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_scifi_lf_length_filtered_tracks_t>(
        arguments,
        value<host_number_of_reconstructed_ut_tracks_t>(arguments) *
          LookingForward::maximum_number_of_candidates_per_ut_track);
      set_size<dev_scifi_lf_length_filtered_atomics_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * LookingForward::num_atomics);
      set_size<dev_scifi_lf_parametrization_length_filter_t>(
        arguments,
        4 * value<host_number_of_reconstructed_ut_tracks_t>(arguments) *
          LookingForward::maximum_number_of_candidates_per_ut_track);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      cudaCheck(cudaMemsetAsync(
        offset<dev_scifi_lf_length_filtered_atomics_t>(arguments),
        0,
        size<dev_scifi_lf_length_filtered_atomics_t>(arguments),
        cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
        Parameters {offset<dev_offsets_ut_tracks_t>(arguments),
                    offset<dev_offsets_ut_track_hit_number_t>(arguments),
                    offset<dev_scifi_lf_tracks_t>(arguments),
                    offset<dev_scifi_lf_atomics_t>(arguments),
                    offset<dev_scifi_lf_length_filtered_tracks_t>(arguments),
                    offset<dev_scifi_lf_length_filtered_atomics_t>(arguments),
                    offset<dev_scifi_lf_parametrization_t>(arguments),
                    offset<dev_scifi_lf_parametrization_length_filter_t>(arguments)});
    }
  };
} // namespace lf_quality_filter_length