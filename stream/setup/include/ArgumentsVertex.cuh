#pragma once

#include "Argument.cuh"
#include "VertexDefinitions.cuh"

ARGUMENT(dev_sv_offsets, uint)
ARGUMENT(dev_sv_atomics, uint)
ARGUMENT(dev_secondary_vertices, VertexFit::TrackMVAVertex)
ARGUMENT(dev_consolidated_svs, VertexFit::TrackMVAVertex)