#pragma once

#include "Common.h"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "UTConsolidated.cuh"
#include "MuonDefinitions.cuh"
#include <string>

__device__ MatchUpstreamMuon::Hit magnetFocalPlaneFromTx2(const KalmanVeloState& state);

__device__ float momentum(float dtx);

__device__ std::tuple<float, float, float, float> stationWindow(
  const KalmanVeloState& state,
  const uint& i_station,
  const MatchUpstreamMuon::Hit& magnet_hit,
  const float& slope,
  const float& station_z,
  const MatchUpstreamMuon::SearchWindows& Windows);

__device__ int findHit(
  const uint& i_station,
  const KalmanVeloState& state,
  const MatchUpstreamMuon::Hit& magnet_hit,
  const Muon::HitsSoA& hits,
  const float& slope,
  const MatchUpstreamMuon::SearchWindows& Windows);

__device__ std::tuple<float, float, float, float> firstStationWindow(
  const float& qop,
  const KalmanVeloState& state,
  const uint& i_station,
  const float& station_z,
  const MatchUpstreamMuon::Hit& magnet_hit,
  const float* magnet_polarity,
  const MatchUpstreamMuon::SearchWindows& Windows);

__device__ bool match(
  const float& qop,
  const KalmanVeloState& state,
  const Muon::HitsSoA& hits,
  const float* magnet_polarity,
  const MatchUpstreamMuon::MuonChambers& MuCh,
  const MatchUpstreamMuon::SearchWindows& Windows);

__device__ std::pair<float, float> fit_linearX(
  const MatchUpstreamMuon::Hit magnet_hit,
  const int* indices,
  const Muon::HitsSoA& muon_hits_event,
  const int no_points);

// namespace MatchUpstreamMuon {

/// Return the track type associated to a given momentum
__device__ inline int trackTypeFromMomentum(float p)
{

  // The following quantities have been set from the references
  // for offline muons in the MuonID, giving room for resolution.

  if (p < 2.5f * Gaudi::Units::GeV) // 3 GeV/c for offline muons
    return MatchUpstreamMuon::VeryLowP;

  else if (p < 7.f * Gaudi::Units::GeV) // 6 GeV/c for offline muons
    return MatchUpstreamMuon::LowP;

  else if (p < 12.f * Gaudi::Units::GeV) // 10 GeV/c for offline muons
    return MatchUpstreamMuon::MediumP;

  else
    return MatchUpstreamMuon::HighP;
}

/// Calculate the projection in the magnet for the "y" axis
__device__ inline float yStraight(const KalmanVeloState& state, float z)
{

  float dz = z - state.z;

  return state.y + dz * state.ty;
}

/// Calculate the projection in the magnet for the "y" axis
__device__ inline std::pair<float, float> yStraightWindow(const KalmanVeloState& state, float z, float yw)
{
  float dz = z - state.z;

  float y = state.y + dz * state.ty;

  float r = dz * sqrtf(state.c33) + yw;

  return {y - r, y + r};
}

__device__ inline float d2(const float& d) { return d * d / 12.f; }

/** Calculate the chi2 of a container.
 *  As an input it takes an STL container of tuples with three values. The
 *  first must be the experimental value (observed), the second the
 *  expectation and the third must correspond to the variance.
 */
// template<class Container>

__device__ inline float
chi2X(const int* indices, const Muon::HitsSoA& muon_hits_event, const int no_points, float a, float b)
{
  float prev = 0;

  for (int i = 0; i < no_points; i++) {

    uint i_h = indices[i];
    float d = muon_hits_event.x[i_h] - (a + b * muon_hits_event.z[i_h]);
    prev += d * d / d2(muon_hits_event.dx[i_h]);
  }
  return prev;
}
