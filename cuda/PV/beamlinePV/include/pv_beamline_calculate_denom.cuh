#pragma once

#include "BeamlinePVConstants.cuh"
#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsPV.cuh"
#include "TrackBeamLineVertexFinder.cuh"
#include "VeloConsolidated.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "FloatOperations.cuh"
#include <cstdint>

__global__ void pv_beamline_calculate_denom(
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number,
  PVTrack* dev_pvtracks,
  float* dev_pvtracks_denom,
  float* dev_zpeaks,
  uint* dev_number_of_zpeaks);

struct pv_beamline_calculate_denom_t : public DeviceAlgorithm {
  constexpr static auto name {"pv_beamline_calculate_denom_t"};
  decltype(global_function(pv_beamline_calculate_denom)) function {pv_beamline_calculate_denom};
  using Arguments = std::tuple<
    dev_atomics_velo,
    dev_velo_track_hit_number,
    dev_pvtracks,
    dev_zpeaks,
    dev_number_of_zpeaks,
    dev_pvtracks_denom>;

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
