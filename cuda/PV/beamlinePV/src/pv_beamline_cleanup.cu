#include "pv_beamline_cleanup.cuh"

__global__ void pv_beamline_cleanup::pv_beamline_cleanup(pv_beamline_cleanup::Parameters parameters) {

  __shared__ uint tmp_number_vertices[1];
  *tmp_number_vertices = 0;

  __syncthreads();

  const uint event_number = blockIdx.x;

  const PV::Vertex* vertices = parameters.dev_multi_fit_vertices + event_number * PV::max_number_vertices;
  PV::Vertex* final_vertices = parameters.dev_multi_final_vertices + event_number * PV::max_number_vertices;
  const uint number_of_multi_fit_vertices = parameters.dev_number_of_multi_fit_vertices[event_number];
  // loop over all rec PVs, check if another one is within certain sigma range, only fill if not
  for (uint i_pv = threadIdx.x; i_pv < number_of_multi_fit_vertices; i_pv += blockDim.x) {
    bool unique = true;
    PV::Vertex vertex1 = vertices[i_pv];
    for (uint j_pv = 0; j_pv < number_of_multi_fit_vertices; j_pv++) {
      if (i_pv == j_pv) continue;
      PV::Vertex vertex2 = vertices[j_pv];
      float z1 = vertex1.position.z;
      float z2 = vertex2.position.z;
      float variance1 = vertex1.cov22;
      float variance2 = vertex2.cov22;
      float chi2_dist = (z1 - z2) * (z1 - z2);
      chi2_dist = chi2_dist / (variance1 + variance2);
      if (chi2_dist < BeamlinePVConstants::CleanUp::minChi2Dist && vertex1.nTracks < vertex2.nTracks) {
        unique = false;
      }
    }
    if (unique) {
      auto vtx_index = atomicAdd(tmp_number_vertices, 1);
      final_vertices[vtx_index] = vertex1;
    }
  }
  __syncthreads();
  parameters.dev_number_of_multi_final_vertices[event_number] = *tmp_number_vertices;
}
