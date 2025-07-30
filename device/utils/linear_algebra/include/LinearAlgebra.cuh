/*****************************************************************************\
* (c) Copyright 2025 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"

namespace LinAlg {

  template<unsigned N>
  __device__ inline bool SolveCholesky(const float* A, const float* R, float* x);

  template<>
  __device__ inline bool SolveCholesky<2>(const float* A, const float* R, float* x)
  {
    // Factorization
    float inv_L00 = __frsqrt_rn(A[0]);
    float L10 = A[1] * inv_L00;
    float inv_L11 = __frsqrt_rn(A[2] - L10 * L10);
    if (!std::isfinite(inv_L00) || !std::isfinite(inv_L11)) return false;
    // Forward
    float Y0 = R[0] * inv_L00;
    float Y1 = (R[1] - L10 * Y0) * inv_L11;
    // Backward
    x[1] = Y1 * inv_L11;
    x[0] = (Y0 - L10 * x[1]) * inv_L00;
    return true;
  }

  template<>
  __device__ inline bool SolveCholesky<3>(const float* A, const float* R, float* x)
  {
    // Factorization
    float inv_L00 = __frsqrt_rn(A[0]);
    float L10 = A[1] * inv_L00;
    float L20 = A[3] * inv_L00;
    float inv_L11 = __frsqrt_rn(A[2] - L10 * L10);
    float L21 = (A[4] - L20 * L10) * inv_L11;
    float inv_L22 = __frsqrt_rn(A[5] - L20 * L20 - L21 * L21);
    if (!std::isfinite(inv_L00) || !std::isfinite(inv_L11) || !std::isfinite(inv_L22)) return false;
    // Forward
    float Y0 = R[0] * inv_L00;
    float Y1 = (R[1] - L10 * Y0) * inv_L11;
    float Y2 = (R[2] - L20 * Y0 - L21 * Y1) * inv_L22;
    // Backward
    x[2] = Y2 * inv_L22;
    x[1] = (Y1 - L21 * x[2]) * inv_L11;
    x[0] = (Y0 - L10 * x[1] - L20 * x[2]) * inv_L00;
    return true;
  }

  template<>
  __device__ inline bool SolveCholesky<4>(const float* A, const float* R, float* x)
  {
    // Factorization
    float inv_L00 = __frsqrt_rn(A[0]);
    float L10 = A[1] * inv_L00;
    float L20 = A[3] * inv_L00;
    float L30 = A[6] * inv_L00;
    float inv_L11 = __frsqrt_rn(A[2] - L10 * L10);
    float L21 = (A[4] - L20 * L10) * inv_L11;
    float L31 = (A[7] - L30 * L10) * inv_L11;
    float inv_L22 = __frsqrt_rn(A[5] - L20 * L20 - L21 * L21);
    float L32 = (A[8] - L30 * L20 - L31 * L21) * inv_L22;
    float inv_L33 = __frsqrt_rn(A[9] - L30 * L30 - L31 * L31 - L32 * L32);
    if (!std::isfinite(inv_L00) || !std::isfinite(inv_L11) || !std::isfinite(inv_L22) || !std::isfinite(inv_L33))
      return false;
    // Forward
    float Y0 = R[0] * inv_L00;
    float Y1 = (R[1] - L10 * Y0) * inv_L11;
    float Y2 = (R[2] - L20 * Y0 - L21 * Y1) * inv_L22;
    float Y3 = (R[3] - L30 * Y0 - L31 * Y1 - L32 * Y2) * inv_L33;
    // Backward
    x[3] = Y3 * inv_L33;
    x[2] = (Y2 - L32 * x[3]) * inv_L22;
    x[1] = (Y1 - L21 * x[2] - L31 * x[3]) * inv_L11;
    x[0] = (Y0 - L10 * x[1] - L20 * x[2] - L30 * x[3]) * inv_L00;
    return true;
  }
} // namespace LinAlg