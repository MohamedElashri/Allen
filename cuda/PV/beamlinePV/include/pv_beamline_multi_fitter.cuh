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

__global__ void pv_beamline_multi_fitter(
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number,
  PVTrack* dev_pvtracks,
  float* dev_pvtracks_denom,
  float* dev_zpeaks,
  uint* dev_number_of_zpeaks,
  PV::Vertex* dev_multi_fit_vertices,
  uint* dev_number_of_multi_fit_vertices,
  float* dev_beamline,
  const float* dev_pvtrack_z);

struct pv_beamline_multi_fitter_t : public DeviceAlgorithm {
  constexpr static auto name {"pv_beamline_multi_fitter_t"};
  decltype(global_function(pv_beamline_multi_fitter)) function {pv_beamline_multi_fitter};
  using Arguments = std::tuple<
    dev_atomics_velo,
    dev_velo_track_hit_number,
    dev_pvtracks,
    dev_zpeaks,
    dev_number_of_zpeaks,
    dev_multi_fit_vertices,
    dev_number_of_multi_fit_vertices,
    dev_pvtracks_denom,
    dev_pvtrack_z>;

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
