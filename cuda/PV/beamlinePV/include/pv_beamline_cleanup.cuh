#pragma once

#include "BeamlinePVConstants.cuh"
#include "Common.h"
#include "Handler.cuh"
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

ALGORITHM(
  pv_beamline_cleanup,
  pv_beamline_cleanup_t,
  ARGUMENTS(
    dev_multi_fit_vertices,
    dev_number_of_multi_fit_vertices,
    dev_multi_final_vertices,
    dev_number_of_multi_final_vertices))
