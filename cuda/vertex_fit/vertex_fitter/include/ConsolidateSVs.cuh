#pragma once

#include "VertexDefinitions.cuh"
#include "Handler.cuh"
#include "ArgumentsVertex.cuh"

__global__ void consolidate_svs(
  uint* dev_sv_atomics,
  VertexFit::TrackMVAVertex* dev_secondary_vertices,
  VertexFit::TrackMVAVertex* dev_consolidated_svs);

ALGORITHM(
  consolidate_svs,
  consolidate_svs_t,
  ARGUMENTS(
    dev_sv_atomics,
    dev_secondary_vertices,
    dev_consolidated_svs))