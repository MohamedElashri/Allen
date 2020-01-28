#pragma once

#include "States.cuh"
#include "ParKalmanMath.cuh"
#include <cstdio>

namespace ParKalmanFilter {

  typedef Vector<5> Vector5;
  typedef SquareMatrix<true, 5> SymMatrix5x5;
  typedef SquareMatrix<false, 5> Matrix5x5;

  // Set a 5x5 diagonal matrix for later use
  [[maybe_unused]] __constant__ static KalmanFloat F_diag[25] = {1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1,
                                                                 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1};

  // Max number of measurements.
  constexpr int nMaxMeasurements = 41; // 25 VELO + 4 UT + 12 SciFi

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

    uint ndof;
    uint ndofV;
    uint ndofT;
    uint nhits;

    bool is_muon;

    // Default constructor.
    __device__ __host__ FittedTrack();

    // Constructor from a VELO state.
    __device__ __host__ FittedTrack(const KalmanVeloState& velo_state, float qop, bool muon);

    // Functions for accessing momentum information.
    __device__ __host__ KalmanFloat p() const;

    __device__ __host__ KalmanFloat pt() const;

    __device__ __host__ KalmanFloat px() const;

    __device__ __host__ KalmanFloat py() const;

    __device__ __host__ KalmanFloat pz() const;

    __device__ __host__ KalmanFloat eta() const;
  };
} // namespace ParKalmanFilter
