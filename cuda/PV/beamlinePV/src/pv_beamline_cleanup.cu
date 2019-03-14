#include "pv_beamline_cleanup.cuh"



__global__ void pv_beamline_cleanup(
  PV::Vertex* dev_multi_fit_vertices,
  uint* dev_number_of_multi_fit_vertices,
  PV::Vertex* dev_multi_final_vertices,
  uint* dev_number_of_multi_final_vertices) {

  const uint event_number = blockIdx.x;
  
  PV::Vertex* vertices = dev_multi_fit_vertices + event_number * PV::max_number_vertices;
  PV::Vertex* final_vertices = dev_multi_final_vertices + event_number * PV::max_number_vertices;
  uint* number_of_multi_fit_vertices = dev_number_of_multi_fit_vertices + event_number;
  if(threadIdx.x == 0) {
    int tmp_number_vertices = 0;
    
    //loop over all rec PVs, check if another one is within certain sigma range, only fill if not
    for(int i_pv = 0; i_pv < number_of_multi_fit_vertices[0]; i_pv++ ) {

      bool unique = true;
      PV::Vertex vertex1 = vertices[i_pv];
      //PVs with such a small z uncertainty are very likely fakes 
      if (vertex1.cov22 < 0.000000001f) continue;
      for(int j_pv = 0; j_pv < tmp_number_vertices; j_pv++) {
        PV::Vertex vertex2 = final_vertices[j_pv];
        float z1 = vertex1.position.z;
        float z2 = vertex2.position.z;
        float variance1 = vertex1.cov22;
        float variance2 = vertex2.cov22;
        float chi2_dist = (z1-z2)*(z1-z2);
        chi2_dist = chi2_dist/(variance1+variance2);
        if(chi2_dist < minChi2Dist) unique = false;

      }
      if (unique) {
        final_vertices[tmp_number_vertices] = vertex1;
        tmp_number_vertices++;
      }
    }
    dev_number_of_multi_final_vertices[event_number] = tmp_number_vertices;
  }


}