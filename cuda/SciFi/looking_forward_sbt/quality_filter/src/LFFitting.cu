#include "LFFitting.cuh"
#include <cmath>
#include <cstdlib>

__device__ float LookingForward::get_average_x_at_reference_plane(
  const int* hits,
  const int n_hits,
  const SciFi::Hits& scifi_hits,
  const float xParams_seed[4],
  const SciFi::Tracking::Arrays* constArrays,
  const MiniState& velo_state,
  const float zMagSlope)
{

  float average_x = 0;
  for (int i_hit = 0; i_hit < n_hits; ++i_hit) {
    const int hit = hits[i_hit];
    const float zHit = scifi_hits.z0[hit];
    const float xFromVelo_Hit = evalCubicParameterization(xParams_seed, zHit);
    const float dSlopeDivPart = 1.f / (zHit - constArrays->zMagnetParams[0]);
    const float dz = 1.e-3f * (zHit - SciFi::Tracking::zReference);
    float xHit = scifi_hits.x0[hit];
    // difference in slope before and after the kick
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

    average_x += xMag + ratio * (xHit + dxCoef - xMag);
  }
  average_x /= n_hits;

  return average_x;
}

__device__ bool LookingForward::fitYProjection_proto(
  const MiniState& velo_state,
  const SciFi::Tracking::Arrays* constArrays,
  const int* uv_hits,
  const int n_uv_hits,
  const SciFi::Hits& scifi_hits,
  float trackParams[SciFi::Tracking::nTrackParams])
{
  //== Fit a line
  const float txs = trackParams[0]; // simplify overgeneral c++ calculation
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
  for (int i_hit = 0; i_hit < n_uv_hits; ++i_hit) {
    int hit = uv_hits[i_hit];
    const float d = -trackToHitDistance(trackParams, scifi_hits, hit) /
                    scifi_hits.dxdy(hit); // TODO multiplication much faster than division!
    const float w = scifi_hits.w(hit);
    const float z = scifi_hits.z0[hit] - SciFi::Tracking::zReference;
    s0 += w;
    sz += w * z;
    sz2 += w * z * z;
    sd += w * d;
    sdz += w * d * z;
  }
  const float den = (s0 * sz2 - sz * sz);
  if (!(fabsf(den) > 1e-5)) {
    return false;
  }
  const float da = (sd * sz2 - sdz * sz) / den;
  const float db = (sdz * s0 - sd * sz) / den;
  trackParams[4] += da;
  trackParams[5] += db;

  // Then parabola fit
  // position in magnet not used for parabola fit, hardly any influence on efficiency
  if (!fitParabola_proto(scifi_hits, uv_hits, n_uv_hits, trackParams, false)) return false;

  return true;
}

__device__ int LookingForward::fitParabola_proto(
  const SciFi::Hits& scifi_hits,
  const int* coordToFit,
  const int n_coordToFit,
  float trackParameters[SciFi::Tracking::nTrackParams],
  const bool xFit)
{

  //== Fit a cubic
  float s0 = 0.f;
  float sz = 0.f;
  float sz2 = 0.f;
  float sz3 = 0.f;
  float sz4 = 0.f;
  float sd = 0.f;
  float sdz = 0.f;
  float sdz2 = 0.f;

  for (int i_hit = 0; i_hit < n_coordToFit; ++i_hit) {
    int hit = coordToFit[i_hit];
    float d = trackToHitDistance(trackParameters, scifi_hits, hit);
    if (!xFit) d *= -1.f / scifi_hits.dxdy(hit);
    float w = scifi_hits.w(hit);
    float z = .001f * (scifi_hits.z0[hit] - SciFi::Tracking::zReference);
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
  if (!(std::fabs(den) > 1e-5f)) return false;
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
  const SciFi::Hits& scifi_hits,
  int* coordToFit,
  const int n_coordToFit,
  float trackParameters[SciFi::Tracking::nTrackParams],
  const bool xFit)
{
  float totChi2 = 0.f;
  int nDoF = -3; // fitted 3 parameters
  for (int i_hit = 0; i_hit < n_coordToFit; ++i_hit) {
    int hit = coordToFit[i_hit];
    float d = trackToHitDistance(trackParameters, scifi_hits, hit);
    if (!xFit) d *= -1.f / scifi_hits.dxdy(hit);
    float w = scifi_hits.w(hit);
    float chi2 = d * d * w;
    totChi2 += chi2;
    ++nDoF;
  }
  if (nDoF < 1) return false;
  trackParameters[7] = totChi2;
  trackParameters[8] = (float) nDoF;

  return true;
}

__device__ void LookingForward::removeOutlier_proto(
  const SciFi::Hits& scifi_hits,
  int* coordToFit,
  int& n_coordToFit,
  const int worst)
{
  int it = 0;
  for (int i=0; i<n_coordToFit; ++i) {
    if (i != worst) {
      coordToFit[it++] = coordToFit[i];
    }
  }
  n_coordToFit = it;
}

__device__ bool LookingForward::quadraticFitX_proto(
  const SciFi::Hits& scifi_hits,
  int* coordToFit,
  int& n_coordToFit,
  float trackParameters[SciFi::Tracking::nTrackParams],
  const bool xFit)
{
  if (n_coordToFit < LookingForward::track_min_hits) return false;
  bool doFit = true;
  while (doFit) {
    fitParabola_proto(scifi_hits, coordToFit, n_coordToFit, trackParameters, true);

    float maxChi2 = 2000.f;
    float totChi2 = 0.f;
    int nDoF = -3; // fitted 3 parameters

    int worst = -1;
    for (int i_hit = 0; i_hit < n_coordToFit; ++i_hit) {
      int hit = coordToFit[i_hit];
      float d = trackToHitDistance(trackParameters, scifi_hits, hit);
      float chi2 = d * d * scifi_hits.w(hit);
      // debug_cout << "d = " << d << ", w = " << scifi_hits.w(hit) << ", chi2 = " << chi2 << std::endl;
      totChi2 += chi2;
      ++nDoF;
      if (chi2 > maxChi2) {
        maxChi2 = chi2;
        worst = i_hit;
      }
    }

    if (nDoF < 1) return false;
    trackParameters[7] = totChi2;
    trackParameters[8] = (float) nDoF;

    // debug_cout << "maxChi2 = " << maxChi2 << ", maxChi2XProjection = " << SciFi::Tracking::maxChi2XProjection << ",
    // totChi2/nDoF = " << totChi2 / nDoF << ", maxChi2PerDoF = " << SciFi::Tracking::maxChi2PerDoF << ", worst hit = "
    // << worst << ", # of hits = " << n_coordToFit << std::endl;

    doFit = false;
    // if (totChi2 / nDoF > SciFi::Tracking::maxChi2PerDoF || maxChi2 > SciFi::Tracking::maxChi2XProjection) {

    // if (worst != -1) {
    //   // if ( totChi2 / nDoF > 5000 ) {
    //   removeOutlier_proto(scifi_hits, coordToFit, n_coordToFit, worst);
    //   if (n_coordToFit < LookingForward::track_min_hits) return false;
    //   doFit = true;
    // }
  }
  return true;
}
