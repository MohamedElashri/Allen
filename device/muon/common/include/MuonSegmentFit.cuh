/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "MuonDefinitions.cuh"
#include "ParticleTypes.cuh"
template<typename T>
__device__ bool applyWeightedFit(MuonTrack& muon_track, T container, bool xz, float padSizeMult = 2.f)
/**
 *Applies line fit to a set of weighted points. It accepts either MuonConsolidated tracks or MuonConst Hits container
 for compatibility reasons. In order not to change the old behaviour on OneMuonTrackLine the padSize is actually
 multiplied by 2, as it was in an old function.

 The function returns a boolean accounting for success and adds the slope and intercept information to the parameter
 MuonTrack muon_track.
 */
//
{
  float sz2, sz, s0, sxz, sx, sx2;
  sz2 = sz = s0 = sxz = sx = sx2 = 0.f;
  unsigned n_hits_track;
  if constexpr (std::is_same<T, const Allen::Views::Muon::Consolidated::Track>::value) {
    n_hits_track = container.number_of_ids();
    for (unsigned i_hit = 0; i_hit < n_hits_track; i_hit++) {
      float z = container.hit(i_hit).z();
      float coord, coorderr;

      if (xz) {
        coord = container.hit(i_hit).x();
        coorderr = padSizeMult * container.hit(i_hit).dx(); // padSizeMult is to keep old FindMuonHits behaviour
      }
      else {
        coord = container.hit(i_hit).y();
        coorderr = padSizeMult * container.hit(i_hit).dy(); // padSizeMult is to keep old FindMuonHits behaviour
      }

      sz2 += z * z / coorderr / coorderr;
      sz += z / coorderr / coorderr;
      s0 += 1.f / coorderr / coorderr;
      sxz += z * coord / coorderr / coorderr;
      sx += coord / coorderr / coorderr;
      sx2 += coord * coord / coorderr / coorderr;
    }
  }

  if constexpr (std::is_same<T, Muon::ConstHits>::value) {
    n_hits_track = muon_track.number_of_hits();
    for (unsigned i_hit = 0; i_hit < 4; i_hit++) {
      if (muon_track.hit(i_hit) == -1) continue;
      float z = container.z(muon_track.hit(i_hit));
      float coord, coorderr;

      if (xz) {
        coord = container.x(muon_track.hit(i_hit));
        coorderr = padSizeMult * container.dx(muon_track.hit(i_hit));
      }
      else {
        coord = container.y(muon_track.hit(i_hit));
        coorderr = padSizeMult * container.dy(muon_track.hit(i_hit));
      }

      sz2 += z * z / coorderr / coorderr;
      sz += z / coorderr / coorderr;
      s0 += 1.f / coorderr / coorderr;
      sxz += z * coord / coorderr / coorderr;
      sx += coord / coorderr / coorderr;
      sx2 += coord * coord / coorderr / coorderr;
    }
  }
  float slope, a, chi2ndof;
  slope = a = chi2ndof = 9999.f;
  float det = sz2 * s0 - sz * sz;
  if (det != 0.f) {
    slope = (sxz * s0 - sx * sz) / det;
    a = (sx * sz2 - sxz * sz) / det;

    chi2ndof = (sx2 + slope * slope * sz2 + a * a * s0 - 2.f * slope * sxz - 2.f * a * sx + 2.f * slope * a * sz) /
               (n_hits_track - 2);
  }
  else
    return false;
  if (xz) {
    muon_track.tx() = slope;
    muon_track.ax() = a;
    muon_track.chi2x() = chi2ndof;
  }
  else {
    muon_track.ty() = slope;
    muon_track.ay() = a;
    muon_track.chi2y() = chi2ndof;
  }
  return true;
}