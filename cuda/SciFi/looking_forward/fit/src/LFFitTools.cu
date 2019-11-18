#include "LFFitTools.cuh"
#include <cmath>
#include <cstdlib>

__device__ std::tuple<float, float, float> LookingForward::lms_y_fit(
  const SciFi::TrackHits& track,
  const uint number_of_uv_hits,
  const SciFi::Hits& scifi_hits,
  const float a1,
  const float b1,
  const float c1,
  const float d_ratio,
  const uint event_offset,
  const LookingForward::Constants* dev_looking_forward_constants)
{
  // Traverse all UV hits
  float y_values[6];
  float z_values[6];
  auto y_mean = 0.f;
  auto z_mean = 0.f;

  for (uint j = 0; j < number_of_uv_hits; ++j) {
    const auto hit_index = event_offset + track.hits[track.hitsNum - number_of_uv_hits + j];
    const auto plane = scifi_hits.planeCode(hit_index) / 2;
    const auto z = scifi_hits.z0[hit_index];
    const auto dz = z - LookingForward::z_mid_t;
    const auto predicted_x = c1 + b1 * dz + a1 * dz * dz * (1.f + d_ratio * dz);
    const auto y =
      (predicted_x - scifi_hits.x0[hit_index]) / dev_looking_forward_constants->Zone_dxdy_uvlayers[(plane + 1) % 2];

    y_values[j] = y;
    z_values[j] = z;
    y_mean += y;
    z_mean += z;
  }
  z_mean /= number_of_uv_hits;
  y_mean /= number_of_uv_hits;

  auto nom = 0.f;
  auto denom = 0.f;
  for (uint j = 0; j < number_of_uv_hits; ++j) {
    nom += (z_values[j] - z_mean) * (y_values[j] - y_mean);
    denom += (z_values[j] - z_mean) * (z_values[j] - z_mean);
  }
  const auto m = nom / denom;
  const auto b = y_mean - m * z_mean;

  auto lms_fit = 0.f;
  for (uint j = 0; j < number_of_uv_hits; ++j) {
    const auto expected_y = b + m * z_values[j];
    lms_fit += (y_values[j] - expected_y) * (y_values[j] - expected_y);
  }

  return {lms_fit / (number_of_uv_hits - 2), b, m};
}

__device__ float LookingForward::x_at_end_scifi(const float* trackParams)
{
  return trackParams[0] + LookingForward::zReferenceEndTDiff *
                            (trackParams[1] + LookingForward::zReferenceEndTDiff *
                                                (trackParams[2] + LookingForward::zReferenceEndTDiff * trackParams[3]));
}

__device__ float LookingForward::y_at_end_scifi(const float* trackParams)
{
  return trackParams[4] +
         LookingForward::zReferenceEndTDiff * (trackParams[5] + LookingForward::zReferenceEndTDiff * trackParams[6]);
}

__device__ float LookingForward::tx_at_end_scifi(const float* trackParams)
{
  return trackParams[1] + LookingForward::zReferenceEndTDiff *
                            (2.f * trackParams[2] + 3.f * LookingForward::zReferenceEndTDiff * trackParams[3]);
}

__device__ float LookingForward::ty_at_end_scifi(const float* trackParams)
{
  return trackParams[5] + LookingForward::zReferenceEndTDiff * 2.f * trackParams[6];
}

__device__ float LookingForward::linear_parameterization(const float p0, const float p1, const float z)
{
  const float dz = z - SciFi::Tracking::zReference;
  return p0 + p1 * dz;
}

__device__ float LookingForward::get_average_x_at_reference_plane_spread(
  const float xAtRef_average,
  const float* hits_x,
  const int n_hits)
{
  float chi2 = 0;
  for (int i = 0; i < n_hits; ++i) {
    const float diff = xAtRef_average - hits_x[i];
    chi2 += diff * diff;
  }
  return chi2 / n_hits;
}

__device__ float LookingForward::get_average_x_at_reference_plane_from_scifi_propagaion(
  const int* hits,
  const uint8_t n_hits,
  const SciFi::Hits& scifi_hits,
  const float qop)
{
  // get slopes tx
  float txs[6];
  for (uint8_t i_hit = 1; i_hit < n_hits; ++i_hit) {
    const float x0 = scifi_hits.x0[hits[i_hit - 1]];
    const float x1 = scifi_hits.x0[hits[i_hit]];
    const float z0 = scifi_hits.z0[hits[i_hit - 1]];
    const float z1 = scifi_hits.z0[hits[i_hit]];
    txs[i_hit] = (x1 - x0) / (z1 - z0);
  }
  txs[0] = txs[1]; // use slope between hits 0 and 1 for first hit as well

  // calculate average x on reference plane
  float average_x = 0.f;
  for (uint8_t i_hit = 1; i_hit < n_hits; ++i_hit) {
    const int hit = hits[i_hit];
    const float zHit = scifi_hits.z0[hit];
    const float xHit = scifi_hits.x0[hit];
    const float dz = SciFi::Tracking::zReference - zHit;
    const float x = LookingForward::scifi_propagation(xHit, txs[i_hit], qop, dz);
    average_x += x;
  }
  average_x /= n_hits;

  return average_x;
}

__device__ float LookingForward::get_x_on_reference_plane(
  const float xHit,
  const float zHit,
  const float xAtRef_initial,
  const SciFi::Tracking::Arrays* constArrays,
  const MiniState& velo_state,
  const float zMagSlope)
{
  const float xFromVelo_Hit = linear_parameterization(xAtRef_initial, velo_state.tx, zHit);
  const float dSlopeDivPart = 1.f / (zHit - constArrays->zMagnetParams[0]);
  const float dz = 1.e-3f * (zHit - SciFi::Tracking::zReference);
  float dSlope = (xFromVelo_Hit - xHit) * dSlopeDivPart;
  // update zMag now that dSlope is known
  float zMag = zMagSlope + constArrays->zMagnetParams[1] * dSlope * dSlope;
  float xMag = xFromVelo_Hit + velo_state.tx * (zMag - zHit);
  // calculate x position on reference plane
  // dxCoef: account for additional bending of track
  // due to fringe field in first station
  // expressed by quadratic and cubic term in z
  float dxCoef = dz * dz * (constArrays->xParams[0] + dz * constArrays->xParams[1]) * dSlope;
  float ratio = (SciFi::Tracking::zReference - zMag) / (zHit - zMag);
  const float x = xMag + ratio * (xHit + dxCoef - xMag);

  return x;
}

__device__ float LookingForward::get_average_x_at_reference_plane(
  const float* hits_x,
  const float* hits_z,
  const uint8_t n_hits,
  const float xAtRef_initial,
  const SciFi::Tracking::Arrays* constArrays,
  const MiniState& velo_state,
  const float zMagSlope)
{
  float average_x = 0;
  for (uint8_t i_hit = 0; i_hit < n_hits; ++i_hit) {
    const float x =
      get_x_on_reference_plane(hits_x[i_hit], hits_z[i_hit], xAtRef_initial, constArrays, velo_state, zMagSlope);
    average_x += x;
  }
  average_x /= n_hits;

  return average_x;
}

__device__ float LookingForward::get_average_and_individual_x_at_reference_plane(
  const float* hits_x,
  const float* hits_z,
  const uint8_t n_hits,
  const float xAtRef_initial,
  const SciFi::Tracking::Arrays* constArrays,
  const MiniState& velo_state,
  const float zMagSlope,
  float* hits_x_atRef)
{
  float average_x = 0;
  for (uint8_t i_hit = 0; i_hit < n_hits; ++i_hit) {
    const float x =
      get_x_on_reference_plane(hits_x[i_hit], hits_z[i_hit], xAtRef_initial, constArrays, velo_state, zMagSlope);
    hits_x_atRef[i_hit] = x;
    average_x += x;
  }
  average_x /= n_hits;

  return average_x;
}

__device__ bool LookingForward::straight_line_fit_y_projection(
  const MiniState& velo_state,
  const SciFi::Tracking::Arrays* constArrays,
  const int* uv_hits,
  const uint8_t n_uv_hits,
  const SciFi::Hits& scifi_hits,
  float trackParams[SciFi::Tracking::nTrackParams])
{
  const float txs = trackParams[0];
  const float tsxz = velo_state.x + (SciFi::Tracking::zReference - velo_state.z) * velo_state.tx;
  const float tolYMag = SciFi::Tracking::tolYMag + SciFi::Tracking::tolYMagSlope * fabsf(txs - tsxz);
  const float wMag = 1.f / (tolYMag * tolYMag);

  // Use position in magnet as constrain in fit
  // although because wMag is quite small only little influence...
  float zMag = zMagnet(velo_state, constArrays);
  const float tys = trackParams[4] + (zMag - SciFi::Tracking::zReference) * trackParams[5];
  const float tsyz = velo_state.y + (zMag - velo_state.z) * velo_state.ty;
  const float dyMag = tys - tsyz;
  zMag -= SciFi::Tracking::zReference;
  float s0 = wMag;
  float sz = wMag * zMag;
  float sz2 = wMag * zMag * zMag;
  float sd = wMag * dyMag;
  float sdz = wMag * dyMag * zMag;

  // First straight line fit
  for (uint8_t i_hit = 0; i_hit < n_uv_hits; ++i_hit) {
    int hit = uv_hits[i_hit];
    const float d = 1.f; // -trackToHitDistance(trackParams, scifi_hits, hit) /
    // scifi_hits.dxdy(hit); // TODO multiplication much faster than division!
    const float w = scifi_hits.w(hit);
    const float z = scifi_hits.z0[hit] - SciFi::Tracking::zReference;
    s0 += w;
    sz += w * z;
    sz2 += w * z * z;
    sd += w * d;
    sdz += w * d * z;
  }
  const float den = (s0 * sz2 - sz * sz);
  if (!(fabsf(den) > 1e-5f)) {
    return false;
  }
  const float da = (sd * sz2 - sdz * sz) / den;
  const float db = (sdz * s0 - sd * sz) / den;
  trackParams[4] += da;
  trackParams[5] += db;

  return true;
}

__device__ float LookingForward::trackToHitDistance(
  const float trackParameters[SciFi::Tracking::nTrackParams],
  const float hit_x,
  const float hit_z,
  const float hit_dxdy)
{
  const float z_Hit = hit_z + SciFi::Constants::dzdy * evalParameterizationY(trackParameters + 4, hit_z);
  const float x_track = evalParameterizationX(trackParameters, z_Hit);
  const float y_track = evalParameterizationY(trackParameters + 4, z_Hit);
  return hit_x + y_track * hit_dxdy - x_track;
}

__device__ int LookingForward::fitParabola_proto(
  const float* hits_x,
  const float* hits_z,
  const float* hits_dxdy,
  const float* hits_w,
  const uint8_t n_coordToFit,
  float trackParameters[SciFi::Tracking::nTrackParams],
  const bool xFit)
{
  //== Fit a cubic (varying only three parameters)
  float s0 = 0.f;
  float sz = 0.f;
  float sz2 = 0.f;
  float sz3 = 0.f;
  float sz4 = 0.f;
  float sd = 0.f;
  float sdz = 0.f;
  float sdz2 = 0.f;

  for (uint8_t i_hit = 0; i_hit < n_coordToFit; ++i_hit) {
    float d = trackToHitDistance(trackParameters, hits_x[i_hit], hits_z[i_hit], hits_dxdy[i_hit]);
    if (!xFit) d *= -1.f / hits_dxdy[i_hit];
    const float w = hits_w[i_hit];
    const float z = .001f * (hits_z[i_hit] - SciFi::Tracking::zReference);
    s0 += w;
    sz += w * z;
    sz2 += w * z * z;
    sz3 += w * z * z * z;
    sz4 += w * z * z * z * z;
    sd += w * d;
    sdz += w * d * z;
    sdz2 += w * d * z * z;
  }
  const float b1 = sz * sz - s0 * sz2;
  const float c1 = sz2 * sz - s0 * sz3;
  const float d1 = sd * sz - s0 * sdz;
  const float b2 = sz2 * sz2 - sz * sz3;
  const float c2 = sz3 * sz2 - sz * sz4;
  const float d2 = sdz * sz2 - sz * sdz2;
  const float den = (b1 * c2 - b2 * c1);
  if (!(fabsf(den) > 1e-5f)) return false;
  const float db = (d1 * c2 - d2 * c1) / den;
  const float dc = (d2 * b1 - d1 * b2) / den;
  const float da = (sd - db * sz - dc * sz2) / s0;
  if (xFit) {
    trackParameters[0] += da;
    trackParameters[1] += db * 1.e-3f;
    trackParameters[2] += dc * 1.e-6f;
  }
  else {
    trackParameters[4] += da;
    trackParameters[5] += db * 1.e-3f;
    trackParameters[6] += dc * 1.e-6f;
  }

  return true;
}

__device__ int LookingForward::getChi2(
  const float* hits_x,
  const float* hits_z,
  const float* hits_dxdy,
  const float* hits_w,
  // const int* coordToFit,
  const uint8_t n_coordToFit,
  float trackParameters[SciFi::Tracking::nTrackParams])
// const bool xFit)
{
  float totChi2 = 0.f;
  int nDoF = -3; // fitted 3 parameters
  for (int i_hit = 0; i_hit < n_coordToFit; ++i_hit) {
    float d = trackToHitDistance(trackParameters, hits_x[i_hit], hits_z[i_hit], hits_dxdy[i_hit]);
    // if (!xFit) d *= -1.f / scifi_hits.dxdy(hit);
    float w = hits_w[i_hit];
    float chi2 = d * d * w;
    totChi2 += chi2;
    ++nDoF;
  }
  if (nDoF < 1) return false;
  trackParameters[7] = totChi2;
  trackParameters[8] = (float) nDoF;

  return true;
}

__device__ void LookingForward::removeOutlier_proto(int* coordToFit, uint8_t& n_coordToFit, const int worst)
{
  uint8_t it = 0;
  for (uint8_t i = 0; i < n_coordToFit; ++i) {
    if (i != worst) {
      coordToFit[it++] = coordToFit[i];
    }
  }
  n_coordToFit = it;
}
