#pragma once

#include "States.cuh"
#include "ParKalmanMath.cuh"
#include <cstdio>
#if !defined(__NVCC__) && !defined(__CUDACC__)
#include <cmath>
#endif

namespace ParKalmanFilter {

  typedef Vector<5> Vector5;
  typedef SquareMatrix<true, 5> SymMatrix5x5;
  typedef SquareMatrix<false, 5> Matrix5x5;

  // Set a 5x5 diagonal matrix for later use
  [[maybe_unused]] __constant__ static KalmanFloat F_diag[25] = {1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1,
                                                                 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1};

  // 26 VELO + 4 UT + 12 SciFi.
  constexpr int nMaxMeasurements = 42; 

  // Max number of bins for the UT <-> SciFi extrapolation.
  constexpr int nBinXMax = 60;
  constexpr int nBinYMax = 50;

  // Number of velo parameters.
  constexpr int nParsV = 10;
  constexpr int nSetsV = 2;

  // Number of velo-UT parameters.
  constexpr int nParsVUT = 30;
  constexpr int nSetsVUT = 2;

  // Number of UT parameters.
  constexpr int nParsUT = 20;
  constexpr int nSetsUT = 7;

  // Number of UTFUT parameters.
  constexpr int nParsUTFUT = 1;
  constexpr int nSetsUTFUT = 1;

  // Number of UTTF parameters.
  constexpr int nParsUTTF = 20;
  constexpr int nSetsUTTF = 2;

  // Number of TFT parameters.
  constexpr int nParsTFT = 20;
  constexpr int nSetsTFT = 2;

  // Number of T parameters.
  constexpr int nParsT = 20;
  constexpr int nSetsT = 46;

  // Number of TLayer parameters.
  constexpr int nParsTLayer = 12;
  constexpr int nSetsTLayer = 2;

  // Number of UTLayer parameters.
  constexpr int nParsUTLayer = 4;
  constexpr int nSetsUTLayer = 1;

  // Some options.
  constexpr bool m_UseForwardMomEstimate = true;
  constexpr bool m_UseForwardChi2Estimate = true;
  constexpr int nMaxOutliers = 2;

  //----------------------------------------------------------------------
  // Tentative output structure.
  struct FittedTrack {

    SymMatrix5x5 cov;
    Vector5 state;

    KalmanFloat z;
    KalmanFloat first_qop;
    KalmanFloat best_qop;
    KalmanFloat chi2;
    KalmanFloat chi2V;
    KalmanFloat chi2T;
    KalmanFloat ipChi2;
    KalmanFloat ip;
    
    unsigned ndof;
    unsigned ndofV;
    unsigned ndofT;
    unsigned nhits;

    bool is_muon;

    __device__ __host__ FittedTrack() {}

    // Constructor from a VELO state.
    __device__ __host__ FittedTrack(const KalmanVeloState& velo_state, float qop, bool muon)
    {
      cov(0, 0) = velo_state.c00;
      cov(1, 0) = 0.;
      cov(2, 0) = velo_state.c20;
      cov(3, 0) = 0.;
      cov(4, 0) = 0.;
      cov(1, 1) = velo_state.c11;
      cov(2, 1) = 0.;
      cov(3, 1) = velo_state.c31;
      cov(4, 1) = 0.;
      cov(2, 2) = velo_state.c22;
      cov(3, 2) = 0.;
      cov(4, 2) = 0.;
      cov(3, 3) = velo_state.c33;
      cov(4, 3) = 0.;
      state[0] = velo_state.x;
      state[1] = velo_state.y;
      state[2] = velo_state.tx;
      state[3] = velo_state.ty;
      state[4] = (KalmanFloat) qop;
      z = velo_state.z;
      first_qop = (KalmanFloat) qop;
      best_qop = (KalmanFloat) qop;
      is_muon = muon;
      // Set so tracks pass fit quality cuts by default.
      chi2 = (KalmanFloat) 0.;
      ndof = 1;
    }

    // Functions for accessing momentum information.
    __device__ __host__ KalmanFloat p() const
    {
      KalmanFloat ret = 1.0f / fabsf(best_qop);
      return ret;
    }

    __device__ __host__ KalmanFloat pt() const
    {
      KalmanFloat sint =
        sqrtf((state[2] * state[2] + state[3] * state[3]) / (1.0f + state[2] * state[2] + state[3] * state[3]));
      return sint / fabsf(best_qop);
    }

    __device__ __host__ KalmanFloat px() const
    {
      return state[2] / fabsf(best_qop) / sqrtf(1.0f + state[2] * state[2] + state[3] * state[3]);
    }

    __device__ __host__ KalmanFloat py() const
    {
      return state[3] / fabsf(best_qop) / sqrtf(1.0f + state[2] * state[2] + state[3] * state[3]);
    }

    __device__ __host__ KalmanFloat pz() const
    {
      KalmanFloat cost = 1.0f / sqrtf(1.0f + state[2] * state[2] + state[3] * state[3]);
      return cost / fabsf(best_qop);
    }

    __device__ __host__ KalmanFloat eta() const { return atanhf(pz() / p()); }
  };
} // namespace ParKalmanFilter
