/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "DiElectronSoftLine.cuh"

INSTANTIATE_LINE(di_electron_soft_line::di_electron_soft_line_t, di_electron_soft_line::Parameters)

__device__ bool di_electron_soft_line::di_electron_soft_line_t::select(
  const Parameters& parameters,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto vertex = std::get<0>(input);
  const bool opposite_sign = vertex.charge() == 0;

  if (!vertex.is_dielectron()) return false;
  if (vertex.minipchi2() < parameters.DESoftMinIPChi2) return false;
  if (opposite_sign != parameters.OppositeSign) return false;

  // brem correction missing still

  const float brem_corrected_dielectron_mass = vertex.m12(0.510999f, 0.510999f); 
  const float dipion_mass = vertex.m12(139.57039f, 139.57039f); 


  // KS pipi misid veto -- needs tuning!
  const bool decision =
    vertex.vertex().chi2() > 0 && (dipion_mass < parameters.DESoftM0 || dipion_mass > parameters.DESoftM1) &&
    (brem_corrected_dielectron_mass < parameters.DESoftM2) && vertex.eta() > 0 &&
    (vertex.vertex().x() * vertex.vertex().x() + vertex.vertex().y() * vertex.vertex().y()) >
      parameters.DESoftMinRho2 &&
    (vertex.vertex().z() > parameters.DESoftMinZ) && (vertex.vertex().z() < parameters.DESoftMaxZ) &&
    vertex.doca12() < parameters.DESoftMaxDOCA && vertex.ip() / vertex.dz() < parameters.DESoftMaxIPDZ &&
    vertex.clone_sin2() > parameters.DESoftGhost;
  return decision;
}
