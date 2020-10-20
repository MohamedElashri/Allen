/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "Common.h"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "UTConsolidated.cuh"
#include "MuonDefinitions.cuh"
#include <string>

/// Get the first estimation of the magnet focal plane position from "tx2".
__device__ MatchUpstreamMuon::Hit magnetFocalPlaneFromTx2(const KalmanVeloState& state)
{
  const auto z = MatchUpstreamMuon::za + MatchUpstreamMuon::zb * state.tx * state.tx;
  const MatchUpstreamMuon::Hit hit {state, z};
  return hit;
}

/// Get the momentum given the slope in "x"
__device__ float momentum(float dtx) { return MatchUpstreamMuon::kickScale / fabsf(dtx) + MatchUpstreamMuon::kickOffset; }

__device__ float dtx(const float& qop) { return MatchUpstreamMuon::kickScale / (fabsf(1.f / qop) - MatchUpstreamMuon::kickOffset); }

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
chi2X(const int* indices, Muon::ConstHits& muon_hits_event, const int no_points, float a, float b)
{
  float prev = 0;

  for (int i = 0; i < no_points; i++) {

    unsigned i_h = indices[i];
    float d = muon_hits_event.x(i_h) - (a + b * muon_hits_event.z(i_h));
    prev += d * d / d2(muon_hits_event.dx(i_h));
  }
  return prev;
}

/** Calculate the window to search in the given station.
 *  Not to be applied in the first station.
 *  Returns "xmin", "xmax", "ymin", "ymax".
 */
__device__ std::tuple<float, float, float, float> stationWindow(
  const KalmanVeloState& state,
  const unsigned& i_station,
  const MatchUpstreamMuon::Hit& magnet_hit,
  const float& slope,
  const float& station_z,
  const MatchUpstreamMuon::SearchWindows& Windows)
{

  auto xRange = Windows.Windows[2 * i_station];
  auto yRange = Windows.Windows[2 * i_station + 1];

  const float yMuon = yStraight(state, station_z);

  const float yMin = yMuon - yRange;

  const float yMax = yMuon + yRange;

  const float xMuon = (station_z - magnet_hit.z) * slope + magnet_hit.x;

  const float xMin = xMuon - xRange;

  const float xMax = xMuon + xRange;

  return {xMin, xMax, yMin, yMax};
}

/** Calculate the window to search in the first station.
 *  Returns "xmin", "xmax", "ymin", "ymax".
 */
__device__ std::tuple<float, float, float, float> firstStationWindow(
  const float& qop,
  const KalmanVeloState& state,
  const unsigned& i_station,
  const float& station_z,
  const MatchUpstreamMuon::Hit& magnet_hit,
  const float* magnet_polarity,
  const MatchUpstreamMuon::SearchWindows& Windows)

{

  auto xw = Windows.Windows[2 * i_station];
  auto yw = Windows.Windows[2 * i_station + 1];

  // Calculate window in y. In y I just extrapolate in a straight line.

  std::pair<float, float> y = yStraightWindow(state, station_z, yw);
  // Calculate window in x
  const float dz = (station_z - magnet_hit.z);

  const int charge = (qop > 0) ? 1 : -1;

  const auto t = state.tx;
  const auto d = dtx(qop);

  const auto slope = charge * magnet_polarity[0] < 0 ? t + d : t - d;

  const auto xpos = magnet_hit.x + dz * slope;
  const auto xMin = xpos - xw;
  const auto xMax = xpos + xw;

  return {xMin, xMax, y.first, y.second};
}

__device__ int findHit(
  const unsigned& i_station,
  const KalmanVeloState& state,
  const MatchUpstreamMuon::Hit& magnet_hit,
  const unsigned* station_ocurrences_offset,
  Muon::ConstHits& muon_hits_event,
  const float& slope,
  const MatchUpstreamMuon::SearchWindows& Windows)
{

  // auto station_z = muon_hits_event.z(i_station);
  // auto [xMin,xMax,yMin,yMax] =
  std::tuple<float, float, float, float> Window =
    stationWindow(state, i_station, magnet_hit, slope, muon_hits_event.z(i_station), Windows);

  // const float xMin = std::get<0>(Window);
  // const float xMax = std::get<1>(Window);
  // const float yMin = std::get<2>(Window);
  // const float yMax = std::get<3>(Window);

  // Look for the closest hit inside the search window
  int closest = -1;

  float min_dist2 = -1.f;

  unsigned station_offset = station_ocurrences_offset[i_station];

  for (unsigned i = 0; i < station_ocurrences_offset[i_station + 1] - station_ocurrences_offset[i_station]; ++i) {

    const int i_h = i + station_offset;

    // MatchUpstreamMuon::Hit hit {muon_hits_event, i_h};

    if (
      (muon_hits_event.x(i_h) > std::get<1>(Window)) || (muon_hits_event.x(i_h) < std::get<0>(Window)) ||
      (muon_hits_event.y(i_h) > std::get<3>(Window)) || (muon_hits_event.y(i_h) < std::get<2>(Window)))
      continue;

    const auto ymuon = yStraight(state, muon_hits_event.z(i_h));

    const auto resx = magnet_hit.x + (muon_hits_event.z(i_h) - magnet_hit.z) * slope - muon_hits_event.x(i_h);
    const auto resy = ymuon - muon_hits_event.y(i_h);

    // Variable to define the closest hit

    // const float dx2 = muon_hits_event.dx(i_h) * muon_hits_event.dx(i_h) / 12;
    // const float dy2 = muon_hits_event.dy(i_h) * muon_hits_event.dy(i_h) / 12;

    const auto dist2 = (resx * resx + resy * resy) / (d2(muon_hits_event.dx(i_h)) + d2(muon_hits_event.dy(i_h)));

    if (closest < 0 || dist2 < min_dist2) {
      closest = i_h;
      min_dist2 = dist2;
    }
  }

  return closest;
}

__device__ std::pair<float, float> fit_linearX(
  const MatchUpstreamMuon::Hit magnet_hit,
  const int* indices, // indices of the points to fit
  Muon::ConstHits& muon_hits_event,
  const int no_points)
{
  // Calculate some sums
  float S = 1.f / magnet_hit.dx2, Sz = magnet_hit.z / magnet_hit.dx2, Sc = magnet_hit.x / magnet_hit.dx2;

  for (int i = 0; i < no_points; i++) {

    unsigned i_h = indices[i];
    float dx2 = d2(muon_hits_event.dx(i_h));

    S += 1.f / dx2;

    Sz += muon_hits_event.z(i_h) / dx2;

    Sc += muon_hits_event.x(i_h) / dx2;
  }

  const float alpha = Sz / S;

  // Calculate the estimate for the slope
  const float t_i_magnet = magnet_hit.z - alpha;

  float b = t_i_magnet * magnet_hit.x / magnet_hit.dx2, Stt = t_i_magnet * t_i_magnet / magnet_hit.dx2;

  for (int i = 0; i < no_points; i++) {

    // MatchUpstreamMuon::Hit it = points[i];
    unsigned i_h = indices[i];

    const float t_i = (muon_hits_event.z(i_h) - alpha);
    // float dx2 = muon_hits_event.dx(i_h) * muon_hits_event.dx(i_h) / 12;
    const float dx2 = d2(muon_hits_event.dx(i_h));
    Stt += t_i * t_i / dx2;
    b += t_i * muon_hits_event.x(i_h) / dx2;
  }

  b /= Stt;

  const float a = (Sc - Sz * b) / S;

  // Calculate the chi2
  const float chisqX = chi2X(indices, muon_hits_event, no_points, a, b);

  return {chisqX, no_points + 1 - 2};
}

__device__ bool match(
  const float& qop,
  const KalmanVeloState& state,
  const unsigned* station_ocurrences_offset,
  Muon::ConstHits& muon_hits_event,
  const float* magnet_polarity,
  const MatchUpstreamMuon::MuonChambers& MuCh,
  const MatchUpstreamMuon::SearchWindows& Windows)
{
  // Define the track type, if its momentum is too low, stop processing
  const int tt = trackTypeFromMomentum(fabsf(1.f / qop));
  if (tt == MatchUpstreamMuon::VeryLowP) return 0;

  // Parametrization of the z-position of the magnet’s focal plane as a function
  // of the direction of the velo track "tx2"
  const auto magnet_hit = magnetFocalPlaneFromTx2(state);

  for (auto it = MuCh.firstOffsets[tt - 1]; it < MuCh.firstOffsets[tt]; it++) {

    const int& ist = MuCh.first[it];
    unsigned station_offset = station_ocurrences_offset[ist];

    std::tuple<float, float, float, float> firstWindow =
      firstStationWindow(qop, state, ist, muon_hits_event.z(station_offset), magnet_hit, magnet_polarity, Windows);

    // const float& xMin = std::get<0>(firstWindow);
    // const float& xMax = std::get<1>(firstWindow);
    // const float& yMin = std::get<2>(firstWindow);
    // const float& yMax = std::get<3>(firstWindow);

    for (unsigned i = 0; i < station_ocurrences_offset[ist + 1] - station_ocurrences_offset[ist]; ++i) {

      int i_h = i + station_offset;

      // MatchUpstreamMuon::Hit hit {muon_hits_event, i_h};

      if (
        (muon_hits_event.x(i_h) > std::get<1>(firstWindow)) || (muon_hits_event.x(i_h) < std::get<0>(firstWindow)) ||
        (muon_hits_event.y(i_h) > std::get<3>(firstWindow)) || (muon_hits_event.y(i_h) < std::get<2>(firstWindow)))
        continue;

      const auto slope = (muon_hits_event.x(i_h) - magnet_hit.x) / (muon_hits_event.z(i_h) - magnet_hit.z);

      // MatchUpstreamMuon::Hit matching_h [5]{magnet_hit,hit};

      int hit_indexes[4] {i_h};

      int matching_hits_len = 1; // constructed with len==1 by definition, needed to know the number o hits
                                 // inside the c-array

      bool is_good = true;

      for (int i = MuCh.afterKickOffsets[tt - 1]; i < MuCh.afterKickOffsets[tt]; i++) {
        // auto& much = muchs[i];
        int hit_index = findHit(MuCh.afterKick[i], state, magnet_hit, station_ocurrences_offset, muon_hits_event, slope, Windows);

        if (hit_index > 0) {
          hit_indexes[matching_hits_len] = hit_index;
          ++matching_hits_len; // += 1;
          // is_good &= true;
        }
        else {
          is_good = false;
          break;
        }
      }

      if (!is_good) continue;

      std::pair<float, float> fit = fit_linearX(magnet_hit, hit_indexes, muon_hits_event, matching_hits_len);

      // const auto chisq = fit.first;
      // const auto ndof = fit.second;

      if (fit.first / fit.second < MatchUpstreamMuon::maxChi2DoF) return true;

    } // Muon stations hits loop

  } // loop over "first muon chambers"

  return false;

} // match
