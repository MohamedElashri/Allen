#pragma once

#include "SciFiDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "CudaCommon.h"

namespace VertexFit {

  // Charged pion mass for calculating Mcor.
  const float mPi = 139.57f;

  // Muon mass.
  const float mMu = 105.66f;

  struct TrackMVAVertex {
    // Fit results.
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
    // Mass assuming dimuon hypothesis.
    float mdimu = 0.0f;
    // Corrected mass.
    float mcor = 0.0f;
    // PV -> SV eta.
    float eta = 0.0f;
    // Minimum IP chi2 of the tracks.
    float minipchi2 = 0.0f;
    // Minimum pt of the tracks.
    float minpt = 0.0f;
    // Number of tracks associated to a PV (min IP chi2 < 16).
    int ntrksassoc = 0;

    // Degrees of freedom.
    int ndof = 0;

    // Muon ID.
    bool is_dimuon;

    __device__ __host__ float pt() { return sqrtf(px * px + py * py); }
    __device__ __host__ float pt() const { return sqrtf(px * px + py * py); }
  };

} // namespace VertexFit
