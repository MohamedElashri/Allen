/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "TwoKsLine.cuh"

INSTANTIATE_LINE(two_ks_line::two_ks_line_t, two_ks_line::Parameters)

__device__ bool two_ks_line::two_ks_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  // Unpack the tuple.
  const auto ks_pair = std::get<0>(input);
  const auto ks1 = static_cast<const Allen::Views::Physics::CompositeParticle*>(ks_pair.child(0));
  const auto ks2 = static_cast<const Allen::Views::Physics::CompositeParticle*>(ks_pair.child(1));

  // Get the first vertex decision.
  // Vertex quality cuts.
  bool dec1 = ks1->vertex().chi2() > 0 && ks1->vertex().chi2() < parameters.maxVertexChi2;
  if (!dec1) return false;
  // Kinematic cuts.
  dec1 &= ks1->minpt() > parameters.minTrackPt_piKs;
  dec1 &= ks1->minp() > parameters.minTrackP_piKs;
  dec1 &= ks1->mdipi() > parameters.minM_Ks;
  dec1 &= ks1->mdipi() < parameters.maxM_Ks;
  dec1 &= ks1->vertex().pt() > parameters.minComboPt_Ks;
  if (!dec1) return false;
  // PV cuts.
  dec1 &= ks1->eta() > parameters.minEta_Ks;
  dec1 &= ks1->eta() < parameters.maxEta_Ks;
  dec1 &= ks1->minipchi2() > parameters.minTrackIPChi2_Ks;
  dec1 &= ks1->dira() > parameters.minCosDira;
  if (!dec1) return false;
  // Cuts that need constituent tracks.
  const auto v1track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(ks1->child(0));
  const auto v1track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(ks1->child(1));
  const auto v1state1 = v1track1->state();
  const auto v1state2 = v1track2->state();
  const float cos1 = (v1state1.px() * v1state2.px() + v1state1.py() * v1state2.py() + v1state1.pz() * v1state2.pz()) /
                     (v1state1.p() * v1state2.p());
  dec1 &= cos1 > parameters.minCosOpening;
  const float v1ip1 = v1track1->ip();
  const float v1ip2 = v1track2->ip();
  const float v1ip = ks1->ip();
  dec1 &= v1ip1 * v1ip2 / v1ip > parameters.min_combip;
  if (!dec1) return false;

  // Get the second vertex decision.
  // Vertex quality cuts.
  bool dec2 = ks2->vertex().chi2() > 0 && ks2->vertex().chi2() < parameters.maxVertexChi2;
  if (!dec2) return false;
  // Kinematic cuts.
  dec2 &= ks2->minpt() > parameters.minTrackPt_piKs;
  dec2 &= ks2->minp() > parameters.minTrackP_piKs;
  dec2 &= ks2->mdipi() > parameters.minM_Ks;
  dec2 &= ks2->mdipi() < parameters.maxM_Ks;
  dec2 &= ks2->vertex().pt() > parameters.minComboPt_Ks;
  if (!dec2) return false;
  // PV cuts.
  dec2 &= ks2->eta() > parameters.minEta_Ks;
  dec2 &= ks2->eta() < parameters.maxEta_Ks;
  dec2 &= ks2->minipchi2() > parameters.minTrackIPChi2_Ks;
  dec2 &= ks2->dira() > parameters.minCosDira;
  if (!dec2) return false;
  // Cuts that need constituent tracks.
  const auto v2track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(ks2->child(0));
  const auto v2track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(ks2->child(1));
  const auto v2state1 = v2track1->state();
  const auto v2state2 = v2track2->state();
  const float cos2 = (v2state1.px() * v2state2.px() + v2state1.py() * v2state2.py() + v2state1.pz() * v2state2.pz()) /
                     (v2state1.p() * v2state2.p());
  dec2 &= cos2 > parameters.minCosOpening;
  const float v2ip1 = v2track1->ip();
  const float v2ip2 = v2track2->ip();
  const float v2ip = ks2->ip();
  dec2 &= v2ip1 * v2ip2 / v2ip > parameters.min_combip;

  return dec1 && dec2;
}
