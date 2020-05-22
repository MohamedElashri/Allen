#pragma once

#include "States.cuh"
#include "UTDefinitions.cuh"
#include "CompassUTDefinitions.cuh"
#include "UTEventModel.cuh"

__device__ inline float eval_log_function(const int N, float& init, const float* a, const float* b)
{
  for (int i = 0; i < N; ++i) {
    init = init + a[i] * logf(b[i]);
  }
  return init;
}

// -- Evaluate the linear discriminant
// -- Coefficients derived with LD method for p, pT and chi2 with TMVA
__device__ inline float evaluateLinearDiscriminant(const float inputValues[3], const int nHits)
{
  float coeffs[4];
  if (nHits == 3) {
    coeffs[0] = 0.162880166064f;
    coeffs[1] = -0.107081172665f;
    coeffs[2] = 0.134153123662f;
    coeffs[3] = -0.137764853657f;
  }
  else {
    coeffs[0] = 0.235010729187f;
    coeffs[1] = -0.0938323617311f;
    coeffs[2] = 0.110823681145f;
    coeffs[3] = -0.170467109599f;
  }
  return eval_log_function(3, coeffs[0], &coeffs[1], &inputValues[0]);
}

/* This function is based on the implementation of fastfitter in
   https://gitlab.cern.ch/lhcb/Rec/blob/master/Pr/PrVeloUT/src/PrVeloUT.cpp
   See this presentation for information:
   https://indico.cern.ch/event/786084/contributions/3326577/attachments/1800737/2937077/20190213_forward.pdf
*/
__device__ inline float fastfitter(
  const BestParams best_params,
  const MiniState& velo_state,
  const int best_hits[UT::Constants::n_layers],
  const float qpxz2p,
  const float* ut_dxDy,
  UT::ConstHits& ut_hits,
  float improvedParams[4])
{

  const float ty = velo_state.ty;
  const float zKink = UT::Constants::magFieldParams_0 - ty * ty * UT::Constants::magFieldParams_1 -
                      ty * ty * ty * ty * UT::Constants::magFieldParams_2;
  const float xMidField = velo_state.x + velo_state.tx * (zKink - velo_state.z);

  const float zDiff = 0.001f * (zKink - UT::Constants::zMidUT);

  // -- This is to avoid division by zero...
  const float pHelper = max(float(fabsf(best_params.qp * qpxz2p)), 1e-9f);
  const float invP = pHelper * sqrtf(1.0f + ty * ty);

  // these resolution are semi-empirical, could be tuned and might not be correct for low momentum.
  // this is the resolution due to multiple scattering between Velo and UT
  const float error1 = 0.14f + 10000.0f * invP;
  // this is the resolution due to the finite Velo resolution
  const float error2 = 0.12f + 3000.0f * invP;
  const float error = error1 * error1 + error2 * error2;
  const float weight = 1.0f / error;

  float mat[6] = {weight, weight * zDiff, weight * zDiff * zDiff, 0.0f, 0.0f, 0.0f};
  float rhs[3] = {weight * xMidField, weight * xMidField * zDiff, 0.0f};

  const float yyProto = velo_state.y - velo_state.ty * velo_state.z;

  for (unsigned i = 0; i < UT::Constants::n_layers; ++i) {
    if (best_hits[i] != -1) {
      const auto hit = best_hits[i];

      const int plane_code = i;
      const float dxDy = ut_dxDy[plane_code];
      const float yy = yyProto + (velo_state.ty * ut_hits.zAtYEq0(hit));
      const float ui = ut_hits.xAt(hit, yy, dxDy);
      const float dz = 0.001f * (ut_hits.zAtYEq0(hit) - UT::Constants::zMidUT);
      const float w = ut_hits.weight(hit);
      const float t = ut_hits.sinT(hit, dxDy);

      mat[0] += w;
      mat[1] += w * dz;
      mat[2] += w * dz * dz;
      mat[3] += w * t;
      mat[4] += w * dz * t;
      mat[5] += w * t * t;

      rhs[0] += w * ui;
      rhs[1] += w * ui * dz;
      rhs[2] += w * ui * t;
    }
  }

  const float a11 = mat[2] * mat[5] - mat[4] * mat[4];
  const float a12 = mat[4] * mat[3] - mat[1] * mat[5];
  const float a13 = mat[1] * mat[4] - mat[2] * mat[3];
  const float a22 = mat[0] * mat[5] - mat[3] * mat[3];
  const float a23 = mat[1] * mat[3] - mat[0] * mat[4];
  const float a33 = mat[0] * mat[2] - mat[1] * mat[1];

  const float det_inv = 1.f / (mat[0] * a11 + mat[1] * a12 + mat[3] * a13);

  const float sol0 = det_inv * (a11 * rhs[0] + a12 * rhs[1] + a13 * rhs[2]);
  const float sol1 = det_inv * (a12 * rhs[0] + a22 * rhs[1] + a23 * rhs[2]);
  const float sol2 = det_inv * (a13 * rhs[0] + a23 * rhs[1] + a33 * rhs[2]);

  const float xUTFit = sol0;
  const float xSlopeUTFit = 0.001f * sol1;
  const float offsetY = sol2;

  const float distX = (xMidField - xUTFit - xSlopeUTFit * (zKink - UT::Constants::zMidUT));
  // -- This takes into account that the distance between a point and track is smaller than the distance on the x-axis
  const float distCorrectionX2 = 1.0f / (1 + xSlopeUTFit * xSlopeUTFit);
  float chi2 = weight * (distX * distX * distCorrectionX2 + offsetY * offsetY / (1.0f + ty * ty));

  for (unsigned i = 0; i < UT::Constants::n_layers; ++i) {
    if (best_hits[i] != -1) {
      const auto hit = best_hits[i];

      const float w = ut_hits.weight(hit);
      const float dz = ut_hits.zAtYEq0(hit) - UT::Constants::zMidUT;
      const int plane_code = i;
      const float dxDy = ut_dxDy[plane_code];
      const float yy = yyProto + (velo_state.ty * ut_hits.zAtYEq0(hit));
      const float x = ut_hits.xAt(hit, yy, dxDy);
      const float dist = (x - xUTFit - xSlopeUTFit * dz - offsetY * ut_hits.sinT(hit, dxDy));
      chi2 += w * dist * dist * distCorrectionX2;
    }
  }

  // new VELO slope x
  const float xb =
    0.5f * ((xUTFit + xSlopeUTFit * (zKink - UT::Constants::zMidUT)) + xMidField); // the 0.5 is empirical
  const float xSlopeVeloFit = (xb - velo_state.x) / (zKink - velo_state.z);

  improvedParams[0] = xUTFit;
  improvedParams[1] = xSlopeUTFit;
  improvedParams[2] = velo_state.y + velo_state.ty * (UT::Constants::zMidUT - velo_state.z) + offsetY;
  improvedParams[3] = chi2;

  // calculate q/p
  const float sinInX = xSlopeVeloFit * sqrtf(1.0f + xSlopeVeloFit * xSlopeVeloFit + ty * ty);
  const float sinOutX = xSlopeUTFit * sqrtf(1.0f + xSlopeUTFit * xSlopeUTFit + ty * ty);
  return (sinInX - sinOutX);
}
