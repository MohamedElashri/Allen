#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "SciFiEventModel.cuh"
#include "DeviceAlgorithm.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsUT.cuh"
#include "ArgumentsSciFi.cuh"
#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "LookingForwardTools.cuh"

__global__ void lf_quality_filter(
  const uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_ut,
  SciFi::TrackHits* dev_scifi_lf_tracks,
  const uint* dev_scifi_lf_atomics,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  uint* dev_atomics_scifi,
  SciFi::TrackHits* dev_scifi_tracks,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float* dev_scifi_lf_parametrization_length_filter,
  float* dev_scifi_lf_y_parametrization_length_filter,
  float* dev_scifi_lf_parametrization_consolidate,
  const MiniState* dev_ut_states,
  const char* dev_velo_states,
  const float* dev_magnet_polarity,
  const uint* dev_atomics_velo,
  const uint* dev_velo_track_hit_number,
  const uint* dev_ut_track_velo_indices);

struct lf_quality_filter_t : public DeviceAlgorithm {
  constexpr static auto name {"lf_quality_filter_t"};
  decltype(global_function(lf_quality_filter)) function {lf_quality_filter};
  using Arguments = std::tuple<
    dev_scifi_hits,
    dev_scifi_hit_count,
    dev_atomics_ut,
    dev_scifi_lf_length_filtered_tracks,
    dev_scifi_lf_length_filtered_atomics,
    dev_atomics_scifi,
    dev_scifi_tracks,
    dev_scifi_lf_parametrization_length_filter,
    dev_scifi_lf_y_parametrization_length_filter,
    dev_scifi_lf_parametrization_consolidate,
    dev_ut_states,
    dev_velo_states,
    dev_atomics_velo,
    dev_velo_track_hit_number,
    dev_ut_track_velo_indices>;

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
