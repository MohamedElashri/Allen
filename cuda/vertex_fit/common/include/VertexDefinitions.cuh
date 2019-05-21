#pragma once

#include "SciFiDefinitions.cuh"
#include "cuda_runtime.h"

namespace VertexFit {

  // Track pT cut.
  const float trackMinPt = 200.0;

  // Track IP chi2 cut.
  //const float trackMinIPChi2 = 6.0;
  const float trackMinIPChi2 = 9.0;
  
  struct Vertex {
    // Fit results.
    //float3 position;
    //float3 momentum;
    float px = 0.0;
    float py = 0.0;
    float pz = 0.0;
    float x = 0.0;
    float y = 0.0;
    float z = 0.0;
    float chi2 = -1.0;
    
    float cov00 = 0.0;
    float cov10 = 0.0;
    float cov11 = 0.0;
    float cov20 = 0.0;
    float cov21 = 0.0;
    float cov22 = 0.0;    
    
    // Additional variables for MVA lines.
    // Sum of track pT.
    float sumpt = 0.0;
    // FD chi2.
    float fdchi2 = 0.0;
    // Corrected mass.
    float mcor = 0.0;
    // PV -> SV eta.
    float eta = 0.0;
    // Number of tracks with IP chi2 < 16.
    int ntrks16 = 0;

    // Degrees of freedom.
    int ndof = 0;

    // Was this SV fitted?
    bool fit = false;
    
    __device__ __host__ float pt()
    {
      return std::sqrt(px * px + py * py);
    }
    __device__ __host__ float pt() const
    {
      return std::sqrt(px * px + py * py);
    }
      
  };

}
