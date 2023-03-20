/*****************************************************************************\
* (c) Copyright 2020 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "DisplacedDiMuonMassLine.cuh"

INSTANTIATE_LINE(displaced_di_muon_mass_line::displaced_di_muon_mass_line_t, displaced_di_muon_mass_line::Parameters)

__device__ bool displaced_di_muon_mass_line::displaced_di_muon_mass_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto vertex = std::get<0>(input);

  if (!vertex.is_dimuon()) return false;
  if (vertex.charge() != parameters.DiMuonCharge) return false;
  if (vertex.minipchi2() < parameters.dispMinIPChi2) return false;
  if (vertex.mdimu() < parameters.minMass) return false;

  bool decision = vertex.vertex().chi2() > 0 && vertex.vertex().chi2() < parameters.maxVertexChi2 &&
                  vertex.eta() > parameters.dispMinEta && vertex.eta() < parameters.dispMaxEta &&
                  vertex.minpt() > parameters.minDispTrackPt && vertex.vertex().z() >= parameters.minZ;
  return decision;
}
