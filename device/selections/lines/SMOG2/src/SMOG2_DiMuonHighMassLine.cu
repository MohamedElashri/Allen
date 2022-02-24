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
  if (vtx.chi2 < 0) {
    return false;
  }

  bool decision = vtx.z < parameters.maxZ && vtx.is_dimuon && vtx.doca < parameters.maxDoca && vtx.mdimu >= parameters.minMass &&
                  vtx.minpt >= parameters.minTrackPt && vtx.minp >= parameters.minTrackP &&
                  vtx.chi2 < parameters.maxVertexChi2 && vtx.z >= parameters.minZ && vtx.charge == parameters.CombCharge;

  return decision;
}
