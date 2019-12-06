#pragma once

#include "Common.h"
#include "GpuAlgorithm.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsPV.cuh"
#include "TrackBeamLineVertexFinder.cuh"
#include "VeloConsolidated.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "patPV_Definitions.cuh"
#include "FloatOperations.cuh"
#include <cstdint>

__global__ void pv_beamline_extrapolate(
  char* dev_velo_kalman_beamline_states,
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number,
  PVTrack* dev_pvtracks,
  float* dev_pvtrack_z);

struct pv_beamline_extrapolate_t : public GpuAlgorithm {
  constexpr static auto name {"pv_beamline_extrapolate_t"};
  decltype(gpu_function(pv_beamline_extrapolate)) function {pv_beamline_extrapolate};
  using Arguments = std::
    tuple<dev_velo_kalman_beamline_states, dev_atomics_velo, dev_velo_track_hit_number, dev_pvtracks, dev_pvtrack_z>;

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
