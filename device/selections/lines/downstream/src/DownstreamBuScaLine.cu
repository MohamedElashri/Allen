/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This sofwqare is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "DownstreamBuScaLine.cuh"
#include <ROOTHeaders.h>
#include "ROOTService.h"

INSTANTIATE_LINE(downstream_mva_busca_line::downstream_mva_busca_line_t, downstream_mva_busca_line::Parameters)

void downstream_mva_busca_line::downstream_mva_busca_line_t::init()
{
  Line<downstream_mva_busca_line::downstream_mva_busca_line_t, downstream_mva_busca_line::Parameters>::init();

  m_busca_scaled.x_axis().minValue = m_histogramMassMin;
  m_busca_scaled.x_axis().maxValue = m_histogramMassMax;
  m_busca_scaled.x_axis().nBins = m_histogramMassNBins;

  m_busca_scaled.y_axis().minValue = m_histogramFDMin;
  m_busca_scaled.y_axis().maxValue = m_histogramFDMax;
  m_busca_scaled.y_axis().nBins = m_histogramFDNBins;
}

__device__ bool downstream_mva_busca_line::downstream_mva_busca_line_t::select(
  const Parameters& parameters,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input)
{
  const auto composite = std::get<0>(input);
  const auto idx = std::get<1>(input);
  const auto& busca_mva = parameters.dev_downstream_mva_busca[idx];

  if (properties.enable_trigger) {

    if (properties.general_line) {
      const float m = composite.m12(Allen::mPi, Allen::mPi); // TODO: insert mass hypotesis
      const float fd = composite.fd();

      const float x = composite.vertex().x();
      const float y = composite.vertex().y();

      const float R = sqrtf(x * x + y * y);
      if (busca_mva > properties.mva_threshold) {
        if (
          (m > properties.trigger_mass_min) && (m < properties.trigger_mass_max) && (fd < properties.trigger_fd_max) &&
          (fd > properties.trigger_fd_min) && R > 25) {
          return true;
        }
      }
    }
    else {
      bool type_selection = false;

      if (properties.muon_line) type_selection = lepton_selection<13>(composite);
      if (properties.electron_line) type_selection = lepton_selection<11>(composite);
      if (properties.hadron_line) type_selection = true;

      if (type_selection && busca_mva > properties.mva_threshold) {

        float m = composite.m12(Allen::mPi, Allen::mPi);
        if (properties.muon_line) m = composite.m12(Allen::mMu, Allen::mMu);
        if (properties.electron_line) m = composite.m12(Allen::mEl, Allen::mEl);

        const float fd = composite.fd();

        const float x = composite.vertex().x();
        const float y = composite.vertex().y();

        const auto dA = static_cast<const Allen::Views::Physics::BasicParticle*>(composite.child(0));
        const auto dB = static_cast<const Allen::Views::Physics::BasicParticle*>(composite.child(1));

        const float dA_p = dA->state().p();
        const float dB_p = dB->state().p();

        if ((dA_p < properties.daughter_momentum_cut) || (dB_p < properties.daughter_momentum_cut)) return false;

        const float quality = composite.vertex().downstream_quality();

        if (quality < properties.downstream_quality_cut) return false;

        const float mass_ks = composite.mdipi();
        const float mass_lambda_1 = composite.m12(Allen::mPi, Allen::mP);
        const float mass_lambda_2 = composite.m12(Allen::mP, Allen::mPi);
        const float mass_ee = composite.m12(Allen::mEl, Allen::mEl);

        const float R = sqrtf(x * x + y * y);
        const float z = composite.vertex().z();

        const float rmin = 0.02f * z - 10.f;
        const float rmax = 0.02f * z + 20.f;

        const bool is_R = (R < rmin) || (R > rmax);

        const bool mass_cut =
          (mass_ks < properties.mass_pipi_lower_threshold || mass_ks > properties.mass_pipi_higher_threshold) &&
          (mass_lambda_1 < properties.mass_ppi_lower_threshold ||
           mass_lambda_1 > properties.mass_ppi_lower_threshold) &&
          (mass_lambda_2 < properties.mass_ppi_lower_threshold ||
           mass_lambda_2 > properties.mass_ppi_lower_threshold) &&
          (mass_ee > properties.mass_ee_cut);

        if (
          (m > properties.trigger_mass_min) && (m < properties.trigger_mass_max) && (fd < properties.trigger_fd_max) &&
          (fd > properties.trigger_fd_min) && (is_R || properties.disable_R_cut) && mass_cut) {
          return true;
        }
      }
    }
  }

  return false;
}

__device__ void downstream_mva_busca_line::downstream_mva_busca_line_t::monitor(
  const Parameters& parameters,
  const DeviceProperties& properties,
  std::tuple<const Allen::Views::Physics::CompositeParticle, const unsigned> input,
  unsigned,
  bool sel)
{
  const auto pair = std::get<0>(input);
  const auto idx = std::get<1>(input);

  const auto& busca_mva = parameters.dev_downstream_mva_busca[idx];

  if (properties.general_line) {
    if (busca_mva > properties.mva_threshold) {
      const float m = pair.m12(Allen::mPi, Allen::mPi); // TODO: insert mass hypotesis
      const float fd = pair.fd();

      const float x = pair.vertex().x();
      const float y = pair.vertex().y();

      const float R = sqrtf(x * x + y * y);

      if (R > 25) {
        properties.busca_scaled.increment(m, fd);
        properties.busca_armenteros.increment(
          pair.vertex().downstream_armentero_podolanski_x(), pair.vertex().downstream_armentero_podolanski_y());
      }
    }

    if (sel) {
      properties.busca_triggered_armenteros.increment(
        pair.vertex().downstream_armentero_podolanski_x(), pair.vertex().downstream_armentero_podolanski_y());
    }
  }
  else {
    bool type_selection = false;
    if (properties.muon_line) type_selection = lepton_selection<13>(pair);
    if (properties.electron_line) type_selection = lepton_selection<11>(pair);
    if (properties.hadron_line) type_selection = true;

    if (type_selection && busca_mva > properties.mva_threshold) {

      const auto dA = static_cast<const Allen::Views::Physics::BasicParticle*>(pair.child(0));
      const auto dB = static_cast<const Allen::Views::Physics::BasicParticle*>(pair.child(1));

      const float dA_p = dA->state().p();
      const float dB_p = dB->state().p();

      const float quality = pair.vertex().downstream_quality();

      if (quality < properties.downstream_quality_cut) return;

      const float mass_ks = pair.mdipi();
      const float mass_lambda_1 = pair.m12(Allen::mPi, Allen::mP);
      const float mass_lambda_2 = pair.m12(Allen::mP, Allen::mPi);
      const float mass_ee = pair.m12(Allen::mEl, Allen::mEl);

      const float x = pair.vertex().x();
      const float y = pair.vertex().y();

      const float R = sqrtf(x * x + y * y);
      const float z = pair.vertex().z();

      const float rmin = 0.02f * z - 10.f;
      const float rmax = 0.02f * z + 20.f;

      const bool is_R = (R < rmin) || (R > rmax);

      const bool mass_cut =
        (mass_ks < properties.mass_pipi_lower_threshold || mass_ks > properties.mass_pipi_higher_threshold) &&
        (mass_lambda_1 < properties.mass_ppi_lower_threshold || mass_lambda_1 > properties.mass_ppi_higher_threshold) &&
        (mass_lambda_2 < properties.mass_ppi_lower_threshold || mass_lambda_2 > properties.mass_ppi_higher_threshold) &&
        (mass_ee > properties.mass_ee_cut);

      float m = pair.m12(Allen::mPi, Allen::mPi);
      if (properties.muon_line) m = pair.m12(Allen::mMu, Allen::mMu);
      if (properties.electron_line) m = pair.m12(Allen::mEl, Allen::mEl);

      const float fd = pair.fd();

      if (
        mass_cut && (is_R || properties.disable_R_cut) && (dA_p > properties.daughter_momentum_cut) &&
        (dB_p > properties.daughter_momentum_cut)) {
        properties.busca_scaled.increment(m, fd);
        properties.busca_armenteros.increment(
          pair.vertex().downstream_armentero_podolanski_x(), pair.vertex().downstream_armentero_podolanski_y());
      }
    }
  }
}

template<int line_type>
__device__ bool downstream_mva_busca_line::downstream_mva_busca_line_t::lepton_selection(
  const Allen::Views::Physics::CompositeParticle composite)
{
  if constexpr (line_type == 13) // muon line
  {
    const auto dA = static_cast<const Allen::Views::Physics::BasicParticle*>(composite.child(0));
    const auto dB = static_cast<const Allen::Views::Physics::BasicParticle*>(composite.child(1));

    bool dA_is_muon = dA->is_muon();
    bool dB_is_muon = dB->is_muon();

    if ((dA_is_muon && dB_is_muon)) return true;
  }

  if constexpr (line_type == 11) // electron line
  {
    const auto dA = static_cast<const Allen::Views::Physics::BasicParticle*>(composite.child(0));
    const auto dB = static_cast<const Allen::Views::Physics::BasicParticle*>(composite.child(1));

    bool dA_is_electron = dA->is_electron();
    bool dB_is_electron = dB->is_electron();

    if ((dA_is_electron && dB_is_electron)) return true;
  }

  return false;
}
