#include "VertexDefinitions.cuh"

__device__ __host__ float VertexFit::TrackMVAVertex::pt() const { return sqrtf(px * px + py * py); }
