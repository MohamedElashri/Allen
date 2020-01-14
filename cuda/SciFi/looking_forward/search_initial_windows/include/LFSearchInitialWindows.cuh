#pragma once

#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "SciFiEventModel.cuh"
#include "SciFiDefinitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"

namespace lf_search_initial_windows {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_ut_tracks_t, uint);
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_hit_count_t, uint) dev_scifi_hit_count;
    DEVICE_INPUT(dev_atomics_velo_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_states_t, char) dev_velo_states;
    DEVICE_INPUT(dev_atomics_ut_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_ut_track_hit_number_t, uint) dev_ut_track_hit_number;
    DEVICE_INPUT(dev_ut_x_t, float) dev_ut_x;
    DEVICE_INPUT(dev_ut_tx_t, float) dev_ut_tx;
    DEVICE_INPUT(dev_ut_z_t, float) dev_ut_z;
    DEVICE_INPUT(dev_ut_qop_t, float) dev_ut_qop;
    DEVICE_INPUT(dev_ut_track_velo_indices_t, uint) dev_ut_track_velo_indices;
    DEVICE_OUTPUT(dev_scifi_lf_initial_windows_t, int) dev_scifi_lf_initial_windows;
    DEVICE_OUTPUT(dev_ut_states_t, MiniState) dev_ut_states;
    DEVICE_OUTPUT(dev_scifi_lf_process_track_t, bool) dev_scifi_lf_process_track;
  };

  __global__ void lf_search_initial_windows(
    Parameters,
    const char* dev_scifi_geometry,
    const float* dev_inv_clus_res,
    const LookingForward::Constants* dev_looking_forward_constants);

  template<typename T, char... S>
  struct lf_search_initial_windows_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(lf_search_initial_windows)) function {lf_search_initial_windows};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_scifi_lf_initial_windows_t>(
        arguments,
        LookingForward::number_of_elements_initial_window * value<host_number_of_reconstructed_ut_tracks_t>(arguments) *
          LookingForward::number_of_x_layers);
      set_size<dev_ut_states_t>(arguments, value<host_number_of_reconstructed_ut_tracks_t>(arguments));
      set_size<dev_scifi_lf_process_track_t>(arguments, value<host_number_of_reconstructed_ut_tracks_t>(arguments));
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
        offset<dev_scifi_lf_initial_windows_t>(arguments),
        0,
        size<dev_scifi_lf_initial_windows_t>(arguments),
        cuda_stream));

      function(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
        Parameters {offset<dev_scifi_hits_t>(arguments),
                    offset<dev_scifi_hit_count_t>(arguments),
                    offset<dev_atomics_velo_t>(arguments),
                    offset<dev_velo_track_hit_number_t>(arguments),
                    offset<dev_velo_states_t>(arguments),
                    offset<dev_atomics_ut_t>(arguments),
                    offset<dev_ut_track_hit_number_t>(arguments),
                    offset<dev_ut_x_t>(arguments),
                    offset<dev_ut_tx_t>(arguments),
                    offset<dev_ut_z_t>(arguments),
                    offset<dev_ut_qop_t>(arguments),
                    offset<dev_ut_track_velo_indices_t>(arguments),
                    offset<dev_scifi_lf_initial_windows_t>(arguments),
                    offset<dev_ut_states_t>(arguments),
                    offset<dev_scifi_lf_process_track_t>(arguments)},
        constants.dev_scifi_geometry,
        constants.dev_inv_clus_res,
        constants.dev_looking_forward_constants);
    }
  };
} // namespace lf_search_initial_windows