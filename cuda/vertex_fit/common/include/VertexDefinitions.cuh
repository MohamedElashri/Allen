#pragma once

#include "SciFiDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "cuda_runtime.h"

namespace VertexFit {

  // Track pT cut.
  const float trackMinPt = 200.0;

  // Track IP chi2 cut.
  const float trackMinIPChi2 = 9.0;

  // Maximum IP chi2 for a track to be associated to a PV.
  const float maxAssocIPChi2 = 16.0;
  
  struct Vertex {
    // Fit results.
    //float3 position;
    //float3 momentum;
    float px = 0.0f;
    float py = 0.0f;
    float pz = 0.0f;
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
    float chi2 = -1.0f;
    
    float cov00 = 0.0f;
    float cov10 = 0.0f;
    float cov11 = 0.0f;
    float cov20 = 0.0f;
    float cov21 = 0.0f;
    float cov22 = 0.0f;    
    
    // Additional variables for MVA lines.
    // Sum of track pT.
    float sumpt = 0.0f;
    // FD chi2.
    float fdchi2 = 0.0f;
    // Corrected mass.
    float mcor = 0.0f;
    // PV -> SV eta.
    float eta = 0.0f;
    // Number of tracks with IP chi2 < 16.
    int ntrks16 = 0;

    // Degrees of freedom.
    int ndof = 0;

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
