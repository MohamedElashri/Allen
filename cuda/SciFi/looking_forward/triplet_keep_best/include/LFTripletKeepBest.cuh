#pragma once

#include "VeloConsolidated.cuh"
#include "UTConsolidated.cuh"
#include "SciFiEventModel.cuh"
#include "SciFiDefinitions.cuh"
#include "GpuAlgorithm.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsUT.cuh"
#include "ArgumentsSciFi.cuh"
#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"

__global__ void lf_triplet_keep_best(
  uint32_t* dev_scifi_hits,
  const uint32_t* dev_scifi_hit_count,
  const uint* dev_atomics_ut,
  const char* dev_scifi_geometry,
  const float* dev_inv_clus_res,
  const LookingForward::Constants* dev_looking_forward_constants,
  SciFi::TrackHits* dev_scifi_tracks,
  uint* dev_atomics_scifi,
  const int* dev_initial_windows,
  const bool* dev_scifi_lf_process_track,
  const int* dev_scifi_lf_found_triplets,
  const int8_t* dev_scifi_lf_number_of_found_triplets,
  uint* dev_scifi_lf_total_number_of_found_triplets);

struct lf_triplet_keep_best_t : public GpuAlgorithm {
  constexpr static auto name {"lf_triplet_keep_best_t"};
  decltype(gpu_function(lf_triplet_keep_best)) function {lf_triplet_keep_best};
  using Arguments = std::tuple<
    dev_scifi_hits,
    dev_scifi_hit_count,
    dev_atomics_ut,
    dev_scifi_lf_tracks,
    dev_scifi_lf_atomics,
    dev_scifi_lf_initial_windows,
    dev_scifi_lf_process_track,
    dev_scifi_lf_found_triplets,
    dev_scifi_lf_number_of_found_triplets,
    dev_scifi_lf_total_number_of_found_triplets>;

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
