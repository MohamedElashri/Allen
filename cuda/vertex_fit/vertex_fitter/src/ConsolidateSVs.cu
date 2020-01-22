#include "ConsolidateSVs.cuh"

__global__ void consolidate_svs::consolidate_svs(consolidate_svs::Parameters parameters)
{
  const uint event_number = blockIdx.x;
  const uint fitted_sv_offset = parameters.dev_sv_offsets[event_number];
  const uint sv_offset = event_number * VertexFit::max_svs;
  const uint n_svs = parameters.dev_sv_offsets[event_number + 1] - parameters.dev_sv_offsets[event_number];
  const VertexFit::TrackMVAVertex* event_svs = parameters.dev_secondary_vertices + sv_offset;
  VertexFit::TrackMVAVertex* event_consolidated_svs = parameters.dev_consolidated_svs + fitted_sv_offset;

  for (int i_sv = threadIdx.x; i_sv < n_svs; i_sv += blockDim.x) {
    event_consolidated_svs[i_sv] = event_svs[i_sv];
  }
}