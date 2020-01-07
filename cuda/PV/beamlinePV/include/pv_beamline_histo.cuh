#pragma once

#include <cstdint>
#include "BeamlinePVConstants.cuh"
#include "Common.h"
#include "TrackBeamLineVertexFinder.cuh"
#include "VeloConsolidated.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "patPV_Definitions.cuh"
#include "DeviceAlgorithm.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsPV.cuh"
#include "FloatOperations.cuh"

__global__ void pv_beamline_histo(
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number,
  PVTrack* dev_pvtracks,
  float* dev_zhisto,
  float* dev_beamline);

struct pv_beamline_histo_t : public DeviceAlgorithm {
  constexpr static auto name {"pv_beamline_histo_t"};
  decltype(global_function(pv_beamline_histo)) function {pv_beamline_histo};
  using Arguments = std::tuple<dev_atomics_velo, dev_velo_track_hit_number, dev_pvtracks, dev_zhisto>;

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
