#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "UTConsolidated.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"

namespace lf_extend_tracks_uv {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_hit_offsets_t, uint) dev_scifi_hit_count;
    DEVICE_INPUT(dev_offsets_ut_tracks_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_offsets_ut_track_hit_number_t, uint) dev_ut_track_hit_number;
    DEVICE_OUTPUT(dev_scifi_lf_tracks_t, SciFi::TrackHits) dev_scifi_lf_tracks;
    DEVICE_INPUT(dev_scifi_lf_atomics_t, uint) dev_scifi_lf_atomics;
    DEVICE_INPUT(dev_ut_states_t, MiniState) dev_ut_states;
    DEVICE_INPUT(dev_scifi_lf_initial_windows_t, int) dev_scifi_lf_initial_windows;
    DEVICE_INPUT(dev_scifi_lf_parametrization_t, float) dev_scifi_lf_parametrization;
    PROPERTY(blockdim_t, DeviceDimensions, "block_dim", "block dimensions", {256, 1, 1});
  };

  __global__ void lf_extend_tracks_uv(
    Parameters,
    const LookingForward::Constants* dev_looking_forward_constants);

  template<typename T, char... S>
  struct lf_extend_tracks_uv_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(lf_extend_tracks_uv)) function {lf_extend_tracks_uv};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {}

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
                    begin<dev_offsets_ut_tracks_t>(arguments),
                    begin<dev_offsets_ut_track_hit_number_t>(arguments),
                    begin<dev_scifi_lf_tracks_t>(arguments),
                    begin<dev_scifi_lf_atomics_t>(arguments),
                    begin<dev_ut_states_t>(arguments),
                    begin<dev_scifi_lf_initial_windows_t>(arguments),
                    begin<dev_scifi_lf_parametrization_t>(arguments)},
        constants.dev_looking_forward_constants);
    }

  private:
    Property<blockdim_t> m_blockdim {this};
  };
} // namespace lf_extend_tracks_uv
