#include "TrackUtils.cuh"

// extrapolate x position from given state to z
__host__ __device__ float xFromVelo(const float z, const MiniState& velo_state)
{
  return velo_state.x + (z - velo_state.z) * velo_state.tx;
}

// extrapolate y position from given state to z
__host__ __device__ float yFromVelo(const float z, const MiniState& velo_state)
{
  return velo_state.y + (z - velo_state.z) * velo_state.ty;
}

__host__ __device__ float evalCubicParameterization(const float params[4], float z)
{
  float dz = z - SciFi::Tracking::zReference;
  return params[0] + (params[1] + (params[2] + params[3] * dz) * dz) * dz;
}

// Find z zMag position within the magnet at which the bending ("kick") occurs
// this is parameterized based on MC
// the second parameter([1]) is multiplied by the difference in slope before and
// after the kick, this slope is calculated from zMag and the x position of the track
// at the reference plane -> it is calculated iteratively later
__host__ __device__ float zMagnet(const MiniState& velo_state, const SciFi::Tracking::Arrays* constArrays)
{

  return (
    constArrays->zMagnetParams[0] + constArrays->zMagnetParams[2] * velo_state.tx * velo_state.tx +
    constArrays->zMagnetParams[3] * velo_state.ty * velo_state.ty);
}

// calculate difference between straight line extrapolation and
// where a track with wrongSignPT (2 GeV) would be on the reference plane (?)
__host__ __device__ float calcDxRef(float pt, const MiniState& velo_state)
{
  const float tx2 = velo_state.tx * velo_state.tx;
  const float ty2 = velo_state.ty * velo_state.ty;
  float m_slope2 = tx2 + ty2;
  return 3973000.f * sqrtf(m_slope2) / pt - 2200.f * ty2 - 1000.f * tx2; // tune this window
}

__host__ __device__ float calcqOverP(
  float bx,
  const SciFi::Tracking::Arrays* constArrays,
  const MiniState& velo_state,
  const float magnet_polarity)
{

  float qop = 1.0f / Gaudi::Units::GeV;
  const float bx2 = bx * bx;
  const float ty2 = velo_state.ty * velo_state.ty;
  const float coef =
    (constArrays->momentumParams[0] + constArrays->momentumParams[1] * bx2 +
     constArrays->momentumParams[2] * bx2 * bx2 + constArrays->momentumParams[3] * bx * velo_state.tx +
     constArrays->momentumParams[4] * ty2 + constArrays->momentumParams[5] * ty2 * ty2);
  const float tx2 = velo_state.tx * velo_state.tx;
  float m_slope2 = tx2 + ty2;
  float proj = sqrtf((1.f + m_slope2) / (1.f + tx2));
  qop = (velo_state.tx - bx) / (coef * Gaudi::Units::GeV * proj * magnet_polarity);
  return qop;
}

__host__ __device__ float evalParameterizationX(const float* params, float z)
{
  const float dz = z - SciFi::Tracking::zReference;
  return params[0] + (params[1] + (params[2] + params[3] * dz) * dz) * dz;
}

__host__ __device__ float evalParameterizationY(const float* params, float z)
{
  const float dz = z - SciFi::Tracking::zReference;
  return params[0] + (params[1] + params[2] * dz) * dz;
}

__host__ __device__ void getTrackParameters(
  float xAtRef,
  const MiniState& velo_state,
  const SciFi::Tracking::Arrays* constArrays,
  float trackParams[SciFi::Tracking::nTrackParams])
{
  float dSlope = (xFromVelo(SciFi::Tracking::zReference, velo_state) - xAtRef) /
                 (SciFi::Tracking::zReference - constArrays->zMagnetParams[0]);
  const float zMagSlope = constArrays->zMagnetParams[2] * velo_state.tx * velo_state.tx +
                          constArrays->zMagnetParams[3] * velo_state.ty * velo_state.ty;
  const float zMag = constArrays->zMagnetParams[0] + constArrays->zMagnetParams[1] * dSlope * dSlope + zMagSlope;
  const float xMag = xFromVelo(zMag, velo_state);
  const float slopeT = (xAtRef - xMag) / (SciFi::Tracking::zReference - zMag);
  dSlope = slopeT - velo_state.tx;
  const float dyCoef = dSlope * dSlope * velo_state.ty;

  trackParams[0] = xAtRef;
  trackParams[1] = slopeT;
  trackParams[2] = 1.e-6f * constArrays->xParams[0] * dSlope;
  trackParams[3] = 1.e-9f * constArrays->xParams[1] * dSlope;
  trackParams[4] = yFromVelo(SciFi::Tracking::zReference, velo_state);
  trackParams[5] = velo_state.ty + dyCoef * SciFi::Tracking::byParams;
  trackParams[6] = dyCoef * SciFi::Tracking::cyParams;
  trackParams[7] = 0.0f;
  trackParams[8] = 0.0f; // last elements are chi2 and ndof, as float
}

__host__ __device__ float
trackToHitDistance(const float trackParameters[SciFi::Tracking::nTrackParams], const SciFi::Hits& scifi_hits, int hit)
{
  const float z_Hit =
    scifi_hits.z0[hit] + scifi_hits.dzdy(hit) * evalParameterizationY(trackParameters + 4, scifi_hits.z0[hit]);
  const float x_track = evalParameterizationX(trackParameters, z_Hit);
  const float y_track = evalParameterizationY(trackParameters + 4, z_Hit);
  return scifi_hits.x0[hit] + y_track * scifi_hits.dxdy(hit) - x_track;
}
