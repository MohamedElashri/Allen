/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "DiMuonMassLine.cuh"

INSTANTIATE_LINE(di_muon_mass_line::di_muon_mass_line_t, di_muon_mass_line::Parameters)

__device__ bool di_muon_mass_line::di_muon_mass_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle&> input)
{
  const auto vertex = std::get<0>(input);
  return vertex.is_dimuon() && vertex.minipchi2() >= parameters.minIPChi2 && vertex.doca12() <= parameters.maxDoca &&
         vertex.mdimu() >= parameters.minMass && vertex.minpt() >= parameters.minHighMassTrackPt &&
         vertex.minp() >= parameters.minHighMassTrackP && vertex.vertex().chi2() > 0 &&
         vertex.vertex().chi2() < parameters.maxVertexChi2;
}
