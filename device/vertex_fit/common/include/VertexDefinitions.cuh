/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "SciFiDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "CudaCommon.h"
#if !defined(__NVCC__) && !defined(__CUDACC__)
#include <cmath>
#endif

namespace VertexFit {

  // Charged pion mass for calculating Mcor.
  constexpr float mPi = 139.57f;

  // Muon mass.
  constexpr float mMu = 105.66f;

  constexpr unsigned max_svs = 1000;

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

    // Store enough info to calculate masses on demand.
    float p1 = 0.f;
    float p2 = 0.f;
    float cos = 1.f;

    // Variables for dimuon lines
    float vertex_ip = 0.0f;
    float dz = 0.0f;
    float doca = -1.f;
    float vertex_clone_sin2 = 0.0f;

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
    // Minimum IP of the tracks.
    float minip = 0.0f;
    // Minimum pt of the tracks.
    float minpt = 0.0f;
    // Number of tracks associated to a PV (min IP chi2 < 16).
    int ntrks16 = 0;

    // Degrees of freedom.
    int ndof = 0;

    // Track indices.
    unsigned trk1 = 0;
    unsigned trk2 = 0;

    // Muon ID.
    bool trk1_is_muon;
    bool trk2_is_muon;
    bool is_dimuon;

    __device__ __host__ float pt() const { return sqrtf(px * px + py * py); }
    __device__ __host__ float m(float m1, float m2) const {
      const float E1 = sqrtf(p1 * p1 + m1 * m1);
      const float E2 = sqrtf(p2 * p2 + m2 * m2);
      return sqrtf(m1 * m1 + m2 * m2 + 2 * E1 * E2 - 2 * p1 * p2 * cos);
    }

  };

} // namespace VertexFit
