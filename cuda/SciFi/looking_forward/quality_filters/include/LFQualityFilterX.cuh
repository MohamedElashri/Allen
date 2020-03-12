#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"
#include "UTConsolidated.cuh"

namespace lf_quality_filter_x {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_ut_tracks_t, uint);
    DEVICE_INPUT(dev_atomics_ut_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_scifi_lf_tracks_t, SciFi::TrackHits) dev_scifi_lf_tracks;
    DEVICE_INPUT(dev_scifi_lf_atomics_t, uint) dev_scifi_lf_atomics;
    DEVICE_OUTPUT(dev_scifi_lf_x_filtered_tracks_t, SciFi::TrackHits) dev_scifi_lf_x_filtered_tracks;
    DEVICE_OUTPUT(dev_scifi_lf_x_filtered_atomics_t, uint) dev_scifi_lf_x_filtered_atomics;
    DEVICE_INPUT(dev_scifi_lf_parametrization_t, float) dev_scifi_lf_parametrization;
    DEVICE_OUTPUT(dev_scifi_lf_parametrization_x_filter_t, float) dev_scifi_lf_parametrization_x_filter;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions", {256, 1, 1});
  };

  __global__ void lf_quality_filter_x(Parameters);

  template<typename T, char... S>
  struct lf_quality_filter_x_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(lf_quality_filter_x)) function {lf_quality_filter_x};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_scifi_lf_x_filtered_tracks_t>(
        arguments,
        value<host_number_of_reconstructed_ut_tracks_t>(arguments) *
          LookingForward::maximum_number_of_candidates_per_ut_track);
      set_size<dev_scifi_lf_x_filtered_atomics_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * LookingForward::num_atomics);
      set_size<dev_scifi_lf_parametrization_x_filter_t>(
        arguments,
        4 * value<host_number_of_reconstructed_ut_tracks_t>(arguments) *
          LookingForward::maximum_number_of_candidates_per_ut_track);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_scifi_lf_x_filtered_atomics_t>(arguments, 0, cuda_stream);

      function(dim3(value<host_number_of_selected_events_t>(arguments), 24), property<block_dim_t>(), cuda_stream)(
        Parameters {begin<dev_atomics_ut_t>(arguments),
                    begin<dev_scifi_lf_tracks_t>(arguments),
                    begin<dev_scifi_lf_atomics_t>(arguments),
                    begin<dev_scifi_lf_x_filtered_tracks_t>(arguments),
                    begin<dev_scifi_lf_x_filtered_atomics_t>(arguments),
                    begin<dev_scifi_lf_parametrization_t>(arguments),
                    begin<dev_scifi_lf_parametrization_x_filter_t>(arguments)});
    }

  private:
    Property<block_dim_t> m_block_dim {this};
  };
} // namespace lf_quality_filter_x
