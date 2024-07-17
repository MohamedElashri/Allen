/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "DiMuonTrackEffLine.cuh"

INSTANTIATE_LINE(di_muon_track_eff_line::di_muon_track_eff_line_t, di_muon_track_eff_line::Parameters)

__device__ bool di_muon_track_eff_line::di_muon_track_eff_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto vertex = std::get<0>(input);
  if (!vertex.is_dimuon()) return false;

  const bool opposite_sign = vertex.charge() == 0;
  if (opposite_sign != parameters.OppositeSign) return false;

  const bool decision = vertex.vertex().chi2() > 0 && vertex.mdimu() > parameters.DMTrackEffM0 &&
                        vertex.mdimu() < parameters.DMTrackEffM1 && vertex.vertex().z() >= parameters.DMTrackEffMinZ;
  return decision;
}
