#pragma once

#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "SciFiEventModel.cuh"
#include "SciFiDefinitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"

namespace lf_triplet_keep_best {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_ut_tracks_t, uint);
    DEVICE_INPUT(dev_offsets_ut_tracks_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, uint) dev_ut_track_hit_number;
    DEVICE_OUTPUT(dev_scifi_lf_tracks_t, SciFi::TrackHits) dev_scifi_lf_tracks;
    DEVICE_OUTPUT(dev_scifi_lf_atomics_t, uint) dev_scifi_lf_atomics;
    DEVICE_INPUT(dev_scifi_lf_initial_windows_t, int) dev_scifi_lf_initial_windows;
    DEVICE_INPUT(dev_scifi_lf_process_track_t, bool) dev_scifi_lf_process_track;
    DEVICE_INPUT(dev_scifi_lf_found_triplets_t, int) dev_scifi_lf_found_triplets;
    DEVICE_INPUT(dev_scifi_lf_number_of_found_triplets_t, int8_t) dev_scifi_lf_number_of_found_triplets;
    DEVICE_OUTPUT(dev_scifi_lf_total_number_of_found_triplets_t, uint) dev_scifi_lf_total_number_of_found_triplets;
  };

  __global__ void lf_triplet_keep_best(
    Parameters,
    const LookingForward::Constants* dev_looking_forward_constants);

  template<typename T, char... S>
  struct lf_triplet_keep_best_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(lf_triplet_keep_best)) function {lf_triplet_keep_best};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_scifi_lf_tracks_t>(
        arguments,
        value<host_number_of_reconstructed_ut_tracks_t>(arguments) *
          LookingForward::maximum_number_of_candidates_per_ut_track);
      set_size<dev_scifi_lf_atomics_t>(
        arguments, value<host_number_of_reconstructed_ut_tracks_t>(arguments) * LookingForward::num_atomics);
      set_size<dev_scifi_lf_total_number_of_found_triplets_t>(
        arguments, value<host_number_of_reconstructed_ut_tracks_t>(arguments));
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
        begin<dev_scifi_lf_total_number_of_found_triplets_t>(arguments),
        0,
        size<dev_scifi_lf_total_number_of_found_triplets_t>(arguments),
        cuda_stream));

      cudaCheck(cudaMemsetAsync(
        begin<dev_scifi_lf_atomics_t>(arguments), 0, size<dev_scifi_lf_atomics_t>(arguments), cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
        Parameters {begin<dev_offsets_ut_tracks_t>(arguments),
                    begin<dev_offsets_ut_track_hit_number_t>(arguments),
                    begin<dev_scifi_lf_tracks_t>(arguments),
                    begin<dev_scifi_lf_atomics_t>(arguments),
                    begin<dev_scifi_lf_initial_windows_t>(arguments),
                    begin<dev_scifi_lf_process_track_t>(arguments),
                    begin<dev_scifi_lf_found_triplets_t>(arguments),
                    begin<dev_scifi_lf_number_of_found_triplets_t>(arguments),
                    begin<dev_scifi_lf_total_number_of_found_triplets_t>(arguments)},
        constants.dev_looking_forward_constants);
    }
  };
} // namespace lf_triplet_keep_best
