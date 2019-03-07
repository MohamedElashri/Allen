#include "LookingForwardFitting.h"
#include <cmath>
#include <cstdlib>

float get_average_x_at_reference_plane(
  std::vector<int> x_hits,
  const SciFi::Hits& scifi_hits,
  const float xParams_seed[4],
  const SciFi::Tracking::Arrays* constArrays,
  const MiniState velo_state,
  const float zMagSlope) 
{
  
  float average_x = 0;
  for ( const auto hit : x_hits ) {
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
    // dxCoef: account for additional bending of track due to fringe field in first station
    // expressed by quadratic and cubic term in z
    float dxCoef = dz * dz * (constArrays->xParams[0] + dz * constArrays->xParams[1]) * dSlope;
    float ratio = (SciFi::Tracking::zReference - zMag) / (zHit - zMag);
    
    average_x += xMag + ratio * (xHit + dxCoef - xMag);
  }
  average_x /= x_hits.size();
  
  return average_x;
}

// the track parameterization is cubic in (z-zRef),
// however only the first three parametres are varied in this fit only
// -> this is a quadratic fit
 bool quadraticFitX(
  const SciFi::Hits& scifi_hits,
  const int event_offset,
  float trackParameters[SciFi::Tracking::nTrackParams],
  SciFi::TrackHits& track)
{

  bool doFit = true;
  while (doFit) {

    fitParabola(track, scifi_hits, event_offset, trackParameters);

    doFit = false;
    
    // float maxChi2 = 0.f;
    // float totChi2 = 0.f;
    // int nDoF = -3; // fitted 3 parameters
    // const bool notMultiple = true;

    // int worst = n_coordToFit;
    // for (int i_hit = 0; i_hit < n_coordToFit; ++i_hit) {
    //   int hit = coordToFit[i_hit];
    //   float d = trackToHitDistance(trackParameters, scifi_hits, hit);
    //   float chi2 = d * d * scifi_hits.w(hit);
    //   totChi2 += chi2;
    //   ++nDoF;
    //   if (chi2 > maxChi2 && (notMultiple || planeCounter.nbInPlane(scifi_hits.planeCode(hit) / 2) > 1)) {
    //     maxChi2 = chi2;
    //     worst = i_hit;
    //   }
    // }
    // if (nDoF < 1) return false;
    // trackParameters[7] = totChi2;
    // trackParameters[8] = (float) nDoF;

    // if (worst == n_coordToFit) {
    //   return true;
    // }
    // doFit = false;
    // if (totChi2 / nDoF > SciFi::Tracking::maxChi2PerDoF || maxChi2 > SciFi::Tracking::maxChi2XProjection) {
    //   removeOutlier(scifi_hits, planeCounter, coordToFit, n_coordToFit, coordToFit[worst]);
    //   if (track.hitsNum < SciFi::LookingForward::minHits) return false;
    //   doFit = true;
    // }
  }
  return true;
}
 
int fitParabola(
  SciFi::TrackHits& track,
  const SciFi::Hits& scifi_hits,
  const int event_offset,
  float trackParameters[SciFi::Tracking::nTrackParams])
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

  for (int i_hit = 0; i_hit < track.hitsNum; ++i_hit) {
    int hit = track.hits[i_hit] + event_offset;
    float d = trackToHitDistance(trackParameters, scifi_hits, hit);
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
  trackParameters[0] += da;
  trackParameters[1] += db * 1.e-3f;
  trackParameters[2] += dc * 1.e-6f;
  
  // calculate chi2
  float totChi2 = 0.f;
  int nDoF = -3; // fitted 3 parameters
  for (int i_hit = 0; i_hit < track.hitsNum; ++i_hit) {
    int hit = track.hits[i_hit] + event_offset;
    float d = trackToHitDistance(trackParameters, scifi_hits, hit);
    float w = scifi_hits.w(hit);
    float chi2 = d * d * w;
    totChi2 += chi2;
    ++nDoF;
  }
  if ( nDoF < 1 ) return false;
  trackParameters[7] = totChi2;
  trackParameters[8] = (float) nDoF;

  return true;
}
