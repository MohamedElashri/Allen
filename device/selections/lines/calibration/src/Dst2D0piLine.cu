/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "Dst2D0piLine.cuh"

INSTANTIATE_LINE(dst_d2kpi_line::dst_d2kpi_line_t, dst_d2kpi_line::Parameters)

__device__ bool dst_d2kpi_line::dst_d2kpi_line_t::select(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input)
{
  const auto particle = std::get<0>(input);
  const auto d0 = static_cast<const Allen::Views::Physics::CompositeParticle*>(particle.child(0));
  const auto pis = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(1));

  const auto d0_c1 = static_cast<const Allen::Views::Physics::BasicParticle*>(d0->child(0));
  const auto d0_c2 = static_cast<const Allen::Views::Physics::BasicParticle*>(d0->child(1));

  const bool c1_is_k = d0_c2->state().charge() == pis->state().charge();

  // Calculate the D0 mass, assuming a RS kaon.
  const float m_d0 = c1_is_k ? d0->m12(Allen::mK, Allen::mPi) : d0->m12(Allen::mPi, Allen::mK);

  // Calculate DeltaM.
  const auto d0_vertex = d0->vertex();
  const auto pis_state = pis->state();
  const auto k_state = c1_is_k ? d0_c1->state() : d0_c2->state();
  const auto pi_state = c1_is_k ? d0_c2->state() : d0_c1->state();
  const float p2_dst = (d0_vertex.px() + pis_state.px()) * (d0_vertex.px() + pis_state.px()) +
                       (d0_vertex.py() + pis_state.py()) * (d0_vertex.py() + pis_state.py()) +
                       (d0_vertex.pz() + pis_state.pz()) * (d0_vertex.pz() + pis_state.pz());
  const float e_dst = pis_state.e(Allen::mPi) + k_state.e(Allen::mK) + pi_state.e(Allen::mPi);
  const float m_dst = sqrtf(e_dst * e_dst - p2_dst);
  const float dm = m_dst - m_d0;

  if (d0_vertex.chi2() < 0) {
    return false;
  }

  const bool decision =
    dm < properties.dmMax && d0_vertex.pt() > properties.minComboPt && d0_vertex.chi2() < properties.maxVertexChi2 &&
    d0->eta() > properties.minEta && d0->eta() < properties.maxEta && d0->doca12() < properties.maxDOCA &&
    d0->minpt() > properties.minTrackPt && d0->has_pv() && d0->minip() > properties.minTrackIP &&
    d0->fdchi2() > properties.minFDChi2 && d0->ctau(Allen::mDz) > properties.ctIPScale * properties.minTrackIP &&
    fabsf(m_d0 - Allen::mDz) < properties.massWindow && d0_vertex.z() >= properties.minZ &&
    d0->pv().position.z >= properties.minZ;
  return decision;
}

__device__ void dst_d2kpi_line::dst_d2kpi_line_t::monitor(
  const Parameters&,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned,
  bool sel)
{
  if (sel) {
    const auto particle = std::get<0>(input);
    const auto d0 = static_cast<const Allen::Views::Physics::CompositeParticle*>(particle.child(0));
    const auto pis = static_cast<const Allen::Views::Physics::BasicParticle*>(particle.child(1));

    const auto d0_c1 = static_cast<const Allen::Views::Physics::BasicParticle*>(d0->child(0));
    const auto d0_c2 = static_cast<const Allen::Views::Physics::BasicParticle*>(d0->child(1));

    const bool c1_is_k = d0_c2->state().charge() == pis->state().charge();

    // Calculate the D0 mass, assuming a RS kaon.
    const float m_d0 = c1_is_k ? d0->m12(Allen::mK, Allen::mPi) : d0->m12(Allen::mPi, Allen::mK);

    // Calculate DeltaM.
    const auto d0_vertex = d0->vertex();
    const auto pis_state = pis->state();
    const auto k_state = c1_is_k ? d0_c1->state() : d0_c2->state();
    const auto pi_state = c1_is_k ? d0_c2->state() : d0_c1->state();
    const float p2_dst = (d0_vertex.px() + pis_state.px()) * (d0_vertex.px() + pis_state.px()) +
                         (d0_vertex.py() + pis_state.py()) * (d0_vertex.py() + pis_state.py()) +
                         (d0_vertex.pz() + pis_state.pz()) * (d0_vertex.pz() + pis_state.pz());
    const float e_dst = pis_state.e(Allen::mPi) + k_state.e(Allen::mK) + pi_state.e(Allen::mPi);
    const float m_dst = sqrtf(e_dst * e_dst - p2_dst);
    const float dm = m_dst - m_d0;
    const float pt = d0_vertex.pt();

    properties.histogram_d0_mass.increment(m_d0);
    properties.histogram_d0_pt.increment(pt);
    properties.histogram_dst_dm.increment(dm);
  }
}

__device__ bool dst_d2kpi_line::dst_d2kpi_line_t::fill_tuples(
  const Parameters& parameters,
  const DeviceProperties&,
  std::tuple<const Allen::Views::Physics::CompositeParticle> input,
  unsigned index,
  bool sel)
{
  if (sel) {
    const auto& particle = std::get<0>(input);
    const auto d0 = static_cast<const Allen::Views::Physics::CompositeParticle*>(particle.child(0));
    // Use the following variables in bandwidth division
    parameters.min_pt[index] = d0->minpt(); // This should range in [250., 2000.]
    parameters.min_ip[index] = d0->minip(); // This should range in [0.06, 0.15]
    parameters.D0_ct[index] = d0->ctau(Allen::mDz);
  }
  return sel;
}
