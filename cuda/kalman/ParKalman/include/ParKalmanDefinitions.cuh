#pragma once

#include "States.cuh"
#include "ParKalmanMath.cuh"
#include <cstdio>
#include <cmath>

namespace ParKalmanFilter {

  typedef Vector<5> Vector5;
  typedef SquareMatrix<true, 5> SymMatrix5x5;
  typedef SquareMatrix<false, 5> Matrix5x5;

  // Set a 5x5 diagonal matrix for later use
  [[maybe_unused]] __constant__ static KalmanFloat F_diag[25] = {1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1,
                                                                 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1};

  // Max number of measurements.
  const int nMaxMeasurements = 41; // 25 VELO + 4 UT + 12 SciFi

  // Max number of bins for the UT <-> SciFi extrapolation.
  const int nBinXMax = 60;
  const int nBinYMax = 50;

  // Number of velo parameters.
  const int nParsV = 10;
  const int nSetsV = 2;

  // Number of velo-UT parameters.
  const int nParsVUT = 30;
  const int nSetsVUT = 2;

  // Number of UT parameters.
  const int nParsUT = 20;
  const int nSetsUT = 7;

  // Number of UTFUT parameters.
  const int nParsUTFUT = 1;
  const int nSetsUTFUT = 1;

  // Number of UTTF parameters.
  const int nParsUTTF = 20;
  const int nSetsUTTF = 2;

  // Number of TFT parameters.
  const int nParsTFT = 20;
  const int nSetsTFT = 2;

  // Number of T parameters.
  const int nParsT = 20;
  const int nSetsT = 46;

  // Number of TLayer parameters.
  const int nParsTLayer = 12;
  const int nSetsTLayer = 2;

  // Number of UTLayer parameters.
  const int nParsUTLayer = 4;
  const int nSetsUTLayer = 1;

  // Some options.
  const bool m_UseForwardMomEstimate = true;
  const bool m_UseForwardChi2Estimate = true;
  const int nMaxOutliers = 2;

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

    uint ndof;
    uint ndofV;
    uint ndofT;
    uint nhits;

    bool is_muon;

    // Default constructor.
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
