/*****************************************************************************\
 * (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "SMOG2_DiMuonHighMassLine.cuh"

INSTANTIATE_LINE(SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t, SMOG2_dimuon_highmass_line::Parameters)

__device__ bool SMOG2_dimuon_highmass_line::SMOG2_dimuon_highmass_line_t::select(
  const Parameters& parameters,
  std::tuple<const VertexFit::TrackMVAVertex&> input)
{
  const auto& vtx = std::get<0>(input);

  bool decision = vtx.is_dimuon && vtx.doca <= parameters.maxDoca && vtx.mdimu >= parameters.minMass &&
                  vtx.minpt >= parameters.minTrackPt && vtx.p1 >= parameters.minTrackP &&
                  vtx.p2 >= parameters.minTrackP && vtx.chi2 > 0 && vtx.chi2 < parameters.maxVertexChi2 &&
                  vtx.z >= parameters.minZ && vtx.z < parameters.maxZ && vtx.charge == parameters.CombCharge;

  return decision;
}
