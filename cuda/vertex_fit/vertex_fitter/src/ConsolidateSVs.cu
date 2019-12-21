#include "ConsolidateSVs.cuh"

__global__ void consolidate_svs(
  uint* dev_sv_atomics,
  VertexFit::TrackMVAVertex* dev_secondary_vertices,
  VertexFit::TrackMVAVertex* dev_consolidated_svs)
{

  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;
  const uint fitted_sv_offset = dev_sv_atomics[event_number + number_of_events];
  const uint sv_offset = event_number * VertexFit::max_svs;
  const uint n_svs = dev_sv_atomics[event_number];
  VertexFit::TrackMVAVertex* event_svs = dev_secondary_vertices + sv_offset;
  VertexFit::TrackMVAVertex* event_consolidated_svs = dev_consolidated_svs + fitted_sv_offset;

  for (int i_sv = threadIdx.x; i_sv < n_svs; i_sv += blockDim.x) {
    event_consolidated_svs[i_sv] = event_svs[i_sv];
  }
}
                                