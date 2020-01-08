#pragma once

#include <stdint.h>
#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsPV.cuh"
#include "patPV_Definitions.cuh"
#include "VeloEventModel.cuh"
#include "VeloConsolidated.cuh"
#include "PV_Definitions.cuh"

__global__ void fit_seeds(
  PV::Vertex* dev_vertex,
  int* dev_number_vertex,
  PatPV::XYZPoint* dev_seeds,
  uint* dev_number_seeds,
  char* dev_velo_kalman_beamline_states,
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number);

__device__ bool fit_vertex(
  PatPV::XYZPoint& seedPoint,
  Velo::Consolidated::KalmanStates velo_states,
  PV::Vertex& vtx,
  int number_of_tracks,
  uint tracks_offset);

__device__ float get_tukey_weight(float trchi2, int iter);

struct pv_fit_seeds_t : public DeviceAlgorithm {
  constexpr static auto name {"pv_fit_seeds_t"};
  decltype(global_function(fit_seeds)) function {fit_seeds};
  using Arguments = std::tuple<
    dev_vertex,
    dev_number_vertex,
    dev_seeds,
    dev_number_seeds,
    dev_velo_kalman_beamline_states,
    dev_atomics_velo,
    dev_velo_track_hit_number>;

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
