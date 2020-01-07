#pragma once

#include "BeamlinePVConstants.cuh"
#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsPV.cuh"
#include "TrackBeamLineVertexFinder.cuh"
#include "VeloConsolidated.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "FloatOperations.cuh"
#include <cstdint>

__global__ void pv_beamline_cleanup(
  PV::Vertex* dev_multi_fit_vertices,
  uint* dev_number_of_multi_fit_vertices,
  PV::Vertex* dev_multi_final_vertices,
  uint* dev_number_of_multi_final_vertices);

struct pv_beamline_cleanup_t : public DeviceAlgorithm {
  constexpr static auto name {"pv_beamline_cleanup_t"};
  decltype(global_function(pv_beamline_cleanup)) function {pv_beamline_cleanup};
  using Arguments = std::tuple<
    dev_multi_fit_vertices,
    dev_number_of_multi_fit_vertices,
    dev_multi_final_vertices,
    dev_number_of_multi_final_vertices>;

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
