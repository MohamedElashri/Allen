/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#include "DiElectronSoftLine.cuh"
#include <ROOTHeaders.h>
#include "ROOTService.h"

INSTANTIATE_LINE(di_electron_soft_line::di_electron_soft_line_t, di_electron_soft_line::Parameters)

__device__ std::tuple<const Allen::Views::Physics::CompositeParticle, const bool, const float, const float>
di_electron_soft_line::di_electron_soft_line_t::get_input(
  const Parameters& parameters,
  const unsigned event_number,
  const unsigned i)
{
  const auto event_vertices = parameters.dev_particle_container->container(event_number);
  const auto vertex = event_vertices.particle(i);
  const auto trk1 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(0));
  const auto trk2 = static_cast<const Allen::Views::Physics::BasicParticle*>(vertex.child(1));
  const bool is_dielectron = vertex.is_dielectron();

  // Bremsstrahlung correction

  const float brem_corrected_pt1 =
    parameters.dev_brem_corrected_pt[parameters.dev_track_offsets[event_number] + trk1->get_index()];
  const float brem_corrected_pt2 =
    parameters.dev_brem_corrected_pt[parameters.dev_track_offsets[event_number] + trk2->get_index()];

  const float raw_pt1 = trk1->state().pt();
  const float raw_pt2 = trk2->state().pt();

  float brem_p_correction_ratio_trk1 = 0.f;
  float brem_p_correction_ratio_trk2 = 0.f;

  if (trk1->state().p() > 0.f) {
    brem_p_correction_ratio_trk1 = brem_corrected_pt1 / raw_pt1;
  }
  if (trk2->state().p() > 0.f) {
    brem_p_correction_ratio_trk2 = brem_corrected_pt2 / raw_pt2;
  }

  const float brem_corrected_dielectron_mass =
    vertex.m12(Allen::mEl, Allen::mEl) * brem_p_correction_ratio_trk1 * brem_p_correction_ratio_trk2;

  // KS2pipi mass for veto
  const float dipion_mass = vertex.m12(Allen::mPi, Allen::mPi);

  return std::forward_as_tuple(vertex, is_dielectron, brem_corrected_dielectron_mass, dipion_mass);
}

__device__ bool di_electron_soft_line::di_electron_soft_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const bool, const float, const float> input)
{
  const auto& [vertex, is_dielectron, brem_corrected_dielectron_mass, dipion_mass] = input;

  const bool opposite_sign = vertex.charge() == 0;

  if (!is_dielectron) return false;
  if (vertex.minip() < properties.DESoftMinIP) return false;
  if (opposite_sign != properties.OppositeSign) return false;

  const bool decision =
    vertex.vertex().chi2() > 0 && (dipion_mass < properties.DESoftM0 || dipion_mass > properties.DESoftM1) &&
    (brem_corrected_dielectron_mass < properties.DESoftM2) && vertex.eta() > 0 &&
    (vertex.vertex().x() * vertex.vertex().x() + vertex.vertex().y() * vertex.vertex().y()) >
      properties.DESoftMinRho2 &&
    (vertex.vertex().z() > properties.DESoftMinZ) && (vertex.vertex().z() < properties.DESoftMaxZ) &&
    vertex.doca12() < properties.DESoftMaxDOCA && vertex.ip() / vertex.dz() < properties.DESoftMaxIPDZ &&
    vertex.clone_sin2() > properties.DESoftGhost;
  return decision;
}

__device__ bool di_electron_soft_line::di_electron_soft_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const bool, const float, const float> input,
  unsigned index,
  bool sel)
{
  const auto& [vertex, is_dielectron, brem_corrected_dielectron_mass, dipion_mass] = input;

  if (sel) {
    parameters.pipi_masses[index] = dipion_mass;
    parameters.ee_masses[index] = brem_corrected_dielectron_mass;
    parameters.minip[index] = vertex.minip();
    parameters.sv_rho2[index] = vertex.vertex().x() * vertex.vertex().x() + vertex.vertex().y() * vertex.vertex().y();
    parameters.sv_z[index] = vertex.vertex().z();
    parameters.ee_doca[index] = vertex.doca12();
    parameters.sv_ipperdz[index] = vertex.ip() / vertex.dz();
    parameters.ee_cloneang[index] = vertex.clone_sin2();
    parameters.sv_pt[index] = vertex.vertex().pt();
    parameters.minpt_uncorr[index] = vertex.minpt();
  }
  return sel;
}
