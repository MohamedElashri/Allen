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
    DEVICE_INPUT(dev_scifi_hits_t, uint) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_hit_count_t, uint) dev_scifi_hit_count;
    DEVICE_INPUT(dev_atomics_velo_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_states_t, uint) dev_velo_states;
    DEVICE_INPUT(dev_atomics_ut_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_ut_track_hit_number_t, uint) dev_ut_track_hit_number;
    DEVICE_INPUT(dev_ut_x_t, uint) dev_ut_x;
    DEVICE_INPUT(dev_ut_tx_t, uint) dev_ut_tx;
    DEVICE_INPUT(dev_ut_z_t, uint) dev_ut_z;
    DEVICE_INPUT(dev_ut_qop_t, uint) dev_ut_qop;
    DEVICE_INPUT(dev_ut_track_velo_indices_t, uint) dev_ut_track_velo_indices;
    DEVICE_INPUT(dev_ut_states_t, uint) dev_ut_states;
    DEVICE_INPUT(dev_scifi_lf_initial_windows_t, uint) dev_scifi_lf_initial_windows;
    DEVICE_INPUT(dev_scifi_lf_process_track_t, uint) dev_scifi_lf_process_track;
  };

  __global__ void lf_search_initial_windows(
    uint32_t* dev_scifi_hits,
    const uint32_t* dev_scifi_hit_count,
    const uint* dev_atomics_velo,
    const uint* dev_velo_track_hit_number,
    const char* dev_velo_states,
    const uint* dev_atomics_ut,
    const uint* dev_ut_track_hit_number,
    const float* dev_ut_x,
    const float* dev_ut_tx,
    const float* dev_ut_z,
    const float* dev_ut_qop,
    const uint* dev_ut_track_velo_indices,
    const char* dev_scifi_geometry,
    const float* dev_inv_clus_res,
    const LookingForward::Constants* dev_looking_forward_constants,
    int* dev_initial_windows,
    MiniState* dev_ut_states,
    bool* dev_scifi_lf_process_track);

  template<typename T>
  struct lf_search_initial_windows_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name {"lf_search_initial_windows_t"};
    decltype(global_function(lf_search_initial_windows)) function {lf_search_initial_windows};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      arguments.set_size<dev_scifi_lf_initial_windows>(
        LookingForward::number_of_elements_initial_window * host_buffers.host_number_of_reconstructed_ut_tracks[0] *
        LookingForward::number_of_x_layers);
      arguments.set_size<dev_ut_states>(host_buffers.host_number_of_reconstructed_ut_tracks[0]);
      arguments.set_size<dev_scifi_lf_process_track>(host_buffers.host_number_of_reconstructed_ut_tracks[0]);
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
        arguments.offset<dev_scifi_lf_initial_windows>(),
        0,
        arguments.size<dev_scifi_lf_initial_windows>(),
        cuda_stream));

      function(dim3(host_buffers.host_number_of_selected_events[0]), block_dimension(), cuda_stream)(
        arguments.offset<dev_scifi_hits>(),
        arguments.offset<dev_scifi_hit_count>(),
        arguments.offset<dev_atomics_velo>(),
        arguments.offset<dev_velo_track_hit_number>(),
        arguments.offset<dev_velo_states>(),
        arguments.offset<dev_atomics_ut>(),
        arguments.offset<dev_ut_track_hit_number>(),
        arguments.offset<dev_ut_x>(),
        arguments.offset<dev_ut_tx>(),
        arguments.offset<dev_ut_z>(),
        arguments.offset<dev_ut_qop>(),
        arguments.offset<dev_ut_track_velo_indices>(),
        constants.dev_scifi_geometry,
        constants.dev_inv_clus_res,
        constants.dev_looking_forward_constants,
        arguments.offset<dev_scifi_lf_initial_windows>(),
        arguments.offset<dev_ut_states>(),
        arguments.offset<dev_scifi_lf_process_track>());
    }
  };
} // namespace lf_search_initial_windows