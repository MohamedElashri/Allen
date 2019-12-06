#pragma once

#include "BeamlinePVConstants.cuh"
#include "Common.h"
#include "GpuAlgorithm.cuh"
#include "ArgumentsPV.cuh"
#include "TrackBeamLineVertexFinder.cuh"
#include "VeloConsolidated.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "patPV_Definitions.cuh"
#include "FloatOperations.cuh"
#include <cstdint>

__global__ void
pv_beamline_peak(float* dev_zhisto, float* dev_zpeaks, uint* dev_number_of_zpeaks, uint number_of_events);

struct pv_beamline_peak_t : public GpuAlgorithm {
  constexpr static auto name {"pv_beamline_peak_t"};
  decltype(gpu_function(pv_beamline_peak)) function {pv_beamline_peak};
  using Arguments = std::tuple<dev_zhisto, dev_zpeaks, dev_number_of_zpeaks>;

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
