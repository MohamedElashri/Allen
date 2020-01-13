#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"
#include "UTConsolidated.cuh"

namespace lf_least_mean_square_fit {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_INPUT(dev_scifi_hit_count_t, uint) dev_scifi_hit_count;
    DEVICE_INPUT(dev_atomics_ut_t, uint) dev_atomics_ut;
    DEVICE_OUTPUT(dev_scifi_tracks_t, SciFi::TrackHits) dev_scifi_tracks;
    DEVICE_INPUT(dev_atomics_scifi_t, uint) dev_atomics_scifi;
    DEVICE_OUTPUT(dev_scifi_lf_parametrization_x_filter_t, float) dev_scifi_lf_parametrization_x_filter;
  };

  __global__ void lf_least_mean_square_fit(Parameters, const LookingForward::Constants* dev_looking_forward_constants);

  template<typename T>
  struct lf_least_mean_square_fit_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name {"lf_least_mean_square_fit_t"};
    decltype(global_function(lf_least_mean_square_fit)) function {lf_least_mean_square_fit};

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
      function(dim3(value<host_number_of_selected_events_t>(arguments)), block_dimension(), cuda_stream)(
        Parameters {offset<dev_scifi_hits_t>(arguments),
                    offset<dev_scifi_hit_count_t>(arguments),
                    offset<dev_atomics_ut_t>(arguments),
                    offset<dev_scifi_tracks_t>(arguments),
                    offset<dev_atomics_scifi_t>(arguments),
                    offset<dev_scifi_lf_parametrization_x_filter_t>(arguments)},
        constants.dev_looking_forward_constants);
    }
  };
} // namespace lf_least_mean_square_fit