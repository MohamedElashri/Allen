#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsUT.cuh"

__global__ void lf_quality_filter_length(
  const uint* dev_atomics_ut,
  const SciFi::TrackHits* dev_scifi_lf_x_filtered_tracks,
  const uint* dev_scifi_lf_x_filtered_atomics,
  SciFi::TrackHits* dev_scifi_lf_length_filtered_tracks,
  uint* dev_scifi_lf_length_filtered_atomics,
  const float* dev_scifi_lf_parametrization_x_filter,
  float* dev_scifi_lf_parametrization_length_filter);

struct lf_quality_filter_length_t : public DeviceAlgorithm {
  constexpr static auto name {"lf_quality_filter_length_t"};
  decltype(global_function(lf_quality_filter_length)) function {lf_quality_filter_length};
  using Arguments = std::tuple<
    dev_atomics_ut,
    dev_scifi_lf_tracks,
    dev_scifi_lf_atomics,
    dev_scifi_lf_length_filtered_tracks,
    dev_scifi_lf_length_filtered_atomics,
    dev_scifi_lf_parametrization,
    dev_scifi_lf_parametrization_length_filter>;

  void set_arguments_size(
    ArgumentRefManager<Arguments> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const;

  void operator()(
    const ArgumentRefManager<Arguments>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
