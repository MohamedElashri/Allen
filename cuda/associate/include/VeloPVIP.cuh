#pragma once

// Associate Velo tracks to PVs using their impact parameter and store
// the calculated values.
#include "PV_Definitions.cuh"
#include "AssociateConsolidated.cuh"
#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsPV.cuh"
#include "ArgumentsKalmanFilter.cuh"

__global__ void velo_pv_ip(
  char* dev_kalman_velo_states,
  uint* dev_atomics_velo,
  uint* dev_velo_track_hit_number,
  PV::Vertex* dev_multi_fit_vertices,
  uint* dev_number_of_multi_fit_vertices,
  char* dev_velo_pv_ip);

struct velo_pv_ip_t : public DeviceAlgorithm {
  constexpr static auto name {"velo_pv_ip_t"};
  decltype(global_function(velo_pv_ip)) function {velo_pv_ip};
  using Arguments = std::tuple<
    dev_velo_kalman_beamline_states,
    dev_atomics_velo,
    dev_velo_track_hit_number,
    dev_multi_fit_vertices,
    dev_number_of_multi_fit_vertices,
    dev_velo_pv_ip>;

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
