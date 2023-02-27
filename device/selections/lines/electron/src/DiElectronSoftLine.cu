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

  // Bremsstrahlung Correction

  const auto track1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto track2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));

  const float brem_corrected_pt1 = parameters.dev_brem_corrected_pt[parameters.dev_track_offsets[event_number] + track1->get_index()];

  const float brem_corrected_pt2 = parameters.dev_brem_corrected_pt[parameters.dev_track_offsets[event_number] + track2->get_index()];

  const float raw_pt1 = track1->state().pt();
  const float raw_pt2 = track2->state().pt();

  float brem_p_correction_ratio_trk1 = 0.f;
  float brem_p_correction_ratio_trk2 = 0.f;

  if (track1->state().p() > 0.f) {
    brem_p_correction_ratio_trk1 = brem_corrected_pt1 / raw_pt1;
  }
  if (track2->state().p() > 0.f) {
    brem_p_correction_ratio_trk2 = brem_corrected_pt2 / raw_pt2;
  }

  const float brem_corrected_dielectron_mass = vertex.m12(0.510999f, 0.510999f) * brem_p_correction_ratio_trk1 * brem_p_correction_ratio_trk2; 

  // KS2pipi misID veto
  const float dipion_mass = vertex.m12(139.57039f, 139.57039f);

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
