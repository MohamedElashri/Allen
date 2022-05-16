/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <cstdio>

#include <States.cuh>
#include <ParKalmanMath.cuh>
#include <BackendCommon.h>

namespace ParKalmanFilter {

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
    bool is_electron;

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
    __device__ __host__ inline KalmanFloat p() const
    {
      KalmanFloat ret = 1.0f / fabsf(best_qop);
      return ret;
    }

    __device__ __host__ inline KalmanFloat pt() const
    {
      KalmanFloat sint =
        sqrtf((state[2] * state[2] + state[3] * state[3]) / (1.0f + state[2] * state[2] + state[3] * state[3]));
      return sint / fabsf(best_qop);
    }

    __device__ __host__ inline KalmanFloat px() const
    {
      return state[2] / fabsf(best_qop) / sqrtf(1.0f + state[2] * state[2] + state[3] * state[3]);
    }

    __device__ __host__ inline KalmanFloat py() const
    {
      return state[3] / fabsf(best_qop) / sqrtf(1.0f + state[2] * state[2] + state[3] * state[3]);
    }

    __device__ __host__ inline KalmanFloat pz() const
    {
      KalmanFloat cost = 1.0f / sqrtf(1.0f + state[2] * state[2] + state[3] * state[3]);
      return cost / fabsf(best_qop);
    }

    __device__ __host__ inline KalmanFloat eta() const { return atanhf(pz() / p()); }
  };
} // namespace ParKalmanFilter
