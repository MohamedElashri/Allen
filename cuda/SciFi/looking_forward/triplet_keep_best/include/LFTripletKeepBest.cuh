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
    DEVICE_INPUT(dev_scifi_hits_t, uint) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_hit_count_t, uint) dev_scifi_hit_count;
    DEVICE_INPUT(dev_atomics_ut_t, uint) dev_atomics_ut;
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
    const char* dev_scifi_geometry,
    const float* dev_inv_clus_res,
    const LookingForward::Constants* dev_looking_forward_constants);

  template<typename T>
  struct lf_triplet_keep_best_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name {"lf_triplet_keep_best_t"};
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
        arguments, value<host_number_of_reconstructed_ut_tracks_t>(arguments) * LookingForward::num_atomics * 2 + 1);
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
        offset<dev_scifi_lf_total_number_of_found_triplets_t>(arguments),
        0,
        size<dev_scifi_lf_total_number_of_found_triplets_t>(arguments),
        cuda_stream));

      cudaCheck(cudaMemsetAsync(
        offset<dev_scifi_lf_atomics_t>(arguments), 0, size<dev_scifi_lf_atomics_t>(arguments), cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
        Parameters {offset<dev_scifi_hits_t>(arguments),
                    offset<dev_scifi_hit_count_t>(arguments),
                    offset<dev_atomics_ut_t>(arguments),
                    offset<dev_scifi_lf_tracks_t>(arguments),
                    offset<dev_scifi_lf_atomics_t>(arguments),
                    offset<dev_scifi_lf_initial_windows_t>(arguments),
                    offset<dev_scifi_lf_process_track_t>(arguments),
                    offset<dev_scifi_lf_found_triplets_t>(arguments),
                    offset<dev_scifi_lf_number_of_found_triplets_t>(arguments),
                    offset<dev_scifi_lf_total_number_of_found_triplets_t>(arguments)},
        constants.dev_scifi_geometry,
        constants.dev_inv_clus_res,
        constants.dev_looking_forward_constants);
    }
  };
} // namespace lf_triplet_keep_best