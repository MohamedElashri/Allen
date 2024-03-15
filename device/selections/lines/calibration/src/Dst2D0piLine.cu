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

void dst_d2kpi_line::dst_d2kpi_line_t::init()
{
  Line<dst_d2kpi_line::dst_d2kpi_line_t, dst_d2kpi_line::Parameters>::init();
#ifndef ALLEN_STANDALONE
  histogram_d0_mass = new gaudi_monitoring::Lockable_Histogram<> {
    {this,
     "d0_mass",
     "m(D0)",
     {property<histogram_d0_mass_nbins_t>(), property<histogram_d0_mass_min_t>(), property<histogram_d0_mass_max_t>()}},
    {}};
  histogram_dst_dm = new gaudi_monitoring::Lockable_Histogram<> {
    {this,
     "dst_dm",
     "m(D*)-m(D0)",
     {property<histogram_dst_dm_nbins_t>(), property<histogram_dst_dm_min_t>(), property<histogram_dst_dm_max_t>()}},
    {}};
  histogram_d0_pt = new gaudi_monitoring::Lockable_Histogram<> {
    {this,
     "d0_pt",
     "pT(D0)",
     {property<histogram_d0_pt_nbins_t>(), property<histogram_d0_pt_min_t>(), property<histogram_d0_pt_max_t>()}},
    {}};
#endif
}

void dst_d2kpi_line::dst_d2kpi_line_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& ro,
  const Constants& c) const
{
  static_cast<Line const*>(this)->set_arguments_size(arguments, ro, c);
  set_size<typename Parameters::dev_histogram_d0_mass_t>(arguments, 100u);
  set_size<typename Parameters::dev_histogram_dst_dm_t>(arguments, 84u);
  set_size<typename Parameters::dev_histogram_d0_pt_t>(arguments, 100u);
}

__device__ bool dst_d2kpi_line::dst_d2kpi_line_t::select(
  const Parameters& parameters,
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

  const bool decision = dm < parameters.dmMax && d0_vertex.pt() > parameters.minComboPt &&
                        d0_vertex.chi2() < parameters.maxVertexChi2 && d0->eta() > parameters.minEta &&
                        d0->eta() < parameters.maxEta && d0->doca12() < parameters.maxDOCA &&
                        d0->minpt() > parameters.minTrackPt && d0->has_pv() && d0->minip() > parameters.minTrackIP &&
                        d0->ctau(Allen::mDz) > parameters.ctIPScale * parameters.minTrackIP &&
                        fabsf(m_d0 - Allen::mDz) < parameters.massWindow && d0_vertex.z() >= parameters.minZ &&
                        d0->pv().position.z >= parameters.minZ;
  return decision;
}

void dst_d2kpi_line::dst_d2kpi_line_t::init_monitor(
  const ArgumentReferences<Parameters>& arguments,
  const Allen::Context& context)
{
  Allen::memset_async<dev_histogram_d0_mass_t>(arguments, 0, context);
  Allen::memset_async<dev_histogram_dst_dm_t>(arguments, 0, context);
  Allen::memset_async<dev_histogram_d0_pt_t>(arguments, 0, context);
}

__device__ void dst_d2kpi_line::dst_d2kpi_line_t::monitor(
  const Parameters& parameters,
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

    if (m_d0 > parameters.histogram_d0_mass_min && m_d0 < parameters.histogram_d0_mass_max) {
      const unsigned int bin = static_cast<unsigned int>(
        (m_d0 - parameters.histogram_d0_mass_min) * parameters.histogram_d0_mass_nbins /
        (parameters.histogram_d0_mass_max - parameters.histogram_d0_mass_min));
      atomicAdd(&parameters.dev_histogram_d0_mass[bin], 1);
    }

    if (pt > parameters.histogram_d0_pt_min && pt < parameters.histogram_d0_pt_max) {
      const unsigned int bin = static_cast<unsigned int>(
        (pt - parameters.histogram_d0_pt_min) * parameters.histogram_d0_pt_nbins /
        (parameters.histogram_d0_pt_max - parameters.histogram_d0_pt_min));
      atomicAdd(&parameters.dev_histogram_d0_pt[bin], 1);
    }

    if (dm > parameters.histogram_dst_dm_min && m_d0 < parameters.histogram_dst_dm_max) {
      const unsigned int bin = static_cast<unsigned int>(
        (m_d0 - parameters.histogram_dst_dm_min) * parameters.histogram_dst_dm_nbins /
        (parameters.histogram_dst_dm_max - parameters.histogram_dst_dm_min));
      atomicAdd(&parameters.dev_histogram_dst_dm[bin], 1);
    }
  }
}

void dst_d2kpi_line::dst_d2kpi_line_t::output_monitor(
  [[maybe_unused]] const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  [[maybe_unused]] const Allen::Context& context) const
{
#ifndef ALLEN_STANDALONE
  gaudi_monitoring::fill(
    arguments,
    context,
    std::tuple {std::tuple {get<dev_histogram_d0_mass_t>(arguments),
                            histogram_d0_mass,
                            property<histogram_d0_mass_min_t>(),
                            property<histogram_d0_mass_max_t>()},
                std::tuple {get<dev_histogram_dst_dm_t>(arguments),
                            histogram_dst_dm,
                            property<histogram_dst_dm_min_t>(),
                            property<histogram_dst_dm_max_t>()},
                std::tuple {get<dev_histogram_d0_pt_t>(arguments),
                            histogram_d0_pt,
                            property<histogram_d0_pt_min_t>(),
                            property<histogram_d0_pt_max_t>()}});
#endif
}

__device__ void dst_d2kpi_line::dst_d2kpi_line_t::fill_tuples(
  const Parameters& parameters,
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
}
