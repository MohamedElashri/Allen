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
    DEVICE_INPUT(dev_scifi_hit_offsets_t, uint) dev_scifi_hit_count;
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint) dev_atomics_velo;
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_states_t, char) dev_velo_states;
    DEVICE_INPUT(dev_offsets_ut_tracks_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, uint) dev_ut_track_hit_number;
    DEVICE_INPUT(dev_ut_x_t, float) dev_ut_x;
    DEVICE_INPUT(dev_ut_tx_t, float) dev_ut_tx;
    DEVICE_INPUT(dev_ut_z_t, float) dev_ut_z;
    DEVICE_INPUT(dev_ut_qop_t, float) dev_ut_qop;
    DEVICE_INPUT(dev_ut_track_velo_indices_t, uint) dev_ut_track_velo_indices;
    DEVICE_OUTPUT(dev_scifi_lf_initial_windows_t, int) dev_scifi_lf_initial_windows;
    DEVICE_OUTPUT(dev_ut_states_t, MiniState) dev_ut_states;
    DEVICE_OUTPUT(dev_scifi_lf_process_track_t, bool) dev_scifi_lf_process_track;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

  __global__ void lf_search_initial_windows(
    Parameters,
    const char* dev_scifi_geometry,
    const LookingForward::Constants* dev_looking_forward_constants,
    const float* dev_magnet_polarity);

  template<typename T>
  struct lf_search_initial_windows_t : public DeviceAlgorithm, Parameters {

    decltype(global_function(lf_search_initial_windows)) function {lf_search_initial_windows};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
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
      const RuntimeOptions&,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_scifi_lf_initial_windows_t>(arguments, 0, cuda_stream);

      function(dim3(value<host_number_of_selected_events_t>(arguments)), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_scifi_hits_t>(arguments),
                    begin<dev_scifi_hit_offsets_t>(arguments),
                    begin<dev_offsets_all_velo_tracks_t>(arguments),
                    begin<dev_offsets_velo_track_hit_number_t>(arguments),
                    begin<dev_velo_states_t>(arguments),
                    begin<dev_offsets_ut_tracks_t>(arguments),
                    begin<dev_offsets_ut_track_hit_number_t>(arguments),
                    begin<dev_ut_x_t>(arguments),
                    begin<dev_ut_tx_t>(arguments),
                    begin<dev_ut_z_t>(arguments),
                    begin<dev_ut_qop_t>(arguments),
                    begin<dev_ut_track_velo_indices_t>(arguments),
                    begin<dev_scifi_lf_initial_windows_t>(arguments),
                    begin<dev_ut_states_t>(arguments),
                    begin<dev_scifi_lf_process_track_t>(arguments)},
        constants.dev_scifi_geometry,
        constants.dev_looking_forward_constants,
        constants.dev_magnet_polarity.data());
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace lf_search_initial_windows
