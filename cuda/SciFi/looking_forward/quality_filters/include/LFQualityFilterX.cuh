#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsUT.cuh"
#include "ArgumentsVelo.cuh"
#include "UTConsolidated.cuh"

__global__ void lf_quality_filter_x(
  const uint* dev_atomics_ut,
  const SciFi::TrackHits* dev_scifi_lf_tracks,
  const uint* dev_scifi_lf_atomics,
  SciFi::TrackHits* dev_scifi_lf_x_filtered_tracks,
  uint* dev_scifi_lf_x_filtered_atomics,
  const float* dev_scifi_lf_parametrization,
  float* dev_scifi_lf_parametrization_x_filter);

struct lf_quality_filter_x_t : public DeviceAlgorithm {
  constexpr static auto name {"lf_quality_filter_x_t"};
  decltype(global_function(lf_quality_filter_x)) function {lf_quality_filter_x};
  using Arguments = std::tuple<
    dev_atomics_ut,
    dev_scifi_lf_tracks,
    dev_scifi_lf_atomics,
    dev_scifi_lf_x_filtered_tracks,
    dev_scifi_lf_x_filtered_atomics,
    dev_scifi_lf_parametrization,
    dev_scifi_lf_parametrization_x_filter>;

  void set_arguments_size(
    ArgumentRefManager<T> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const;

  void operator()(
    const ArgumentRefManager<T>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
