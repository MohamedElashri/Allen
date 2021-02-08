/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
/** @file TrackChecker.cpp
 *
 * @brief check tracks against MC truth
 *
 * @author Rainer Schwemmer
 * @author Daniel Campora
 * @author Manuel Schiller
 * @date 2018-02-19
 *
 * 2018-07 Dorothea vom Bruch: updated to run over different track types,
 * use exact same categories as PrChecker2,
 * take input from Renato Quagliani's TrackerDumper
 *
 * 10-12/2018 Dorothea vom Bruch: add histograms of track efficiency, ghost rate,
 * momentum resolution
 *
 * 03/2018 Dorothea vom Bruch: adapt to same track - MCP association as in Rec
 */

#include <cstdio>

#include "TrackChecker.h"
#include "TrackCheckerCategories.h"

namespace {
  using Checker::HistoCategory;
}

// LHCb::Track::pseudoRapidity() is based on slopes vector (Gaudi::XYZVector = ROOT::Match::XYZVector)
// slopes = (Tx=dx/dz,Ty=dy/dz,1.)
// eta() for XYZVector:
// https://root.cern.ch/doc/v608/namespaceROOT_1_1Math_1_1Impl.html#a7d4efefe2855d886fdbae73c81adc574 z = 1.f -> can
// simplify eta_from_rho_z
float eta_from_rho(const float rho)
{
  const float z = 1.f;
  if (rho > 0.f) {

    // value to control Taylor expansion of sqrt
    static const float big_z_scaled = std::pow(std::numeric_limits<float>::epsilon(), static_cast<float>(-.25));

    float z_scaled = z / rho;
    if (std::fabs(z_scaled) < big_z_scaled) {
      return std::log(z_scaled + std::sqrt(z_scaled * z_scaled + 1.f));
    }
    else {
      // apply correction using first order Taylor expansion of sqrt
      return z > 0.f ? std::log(2.f * z_scaled + 0.5f / z_scaled) : -std::log(-2.f * z_scaled);
    }
  }
  // case vector has rho = 0
  return z + 22756.f;
}

void Checker::TrackEffReport::event_start()
{
  m_naccept_per_event = 0;
  m_nfound_per_event = 0;
}

void Checker::TrackEffReport::event_done()
{
  if (m_naccept_per_event) {
    m_number_of_events++;
    const float eff = float(m_nfound_per_event) / float(m_naccept_per_event);
    m_eff_per_event += eff;
  }
}

void Checker::TrackEffReport::operator()(const MCParticles& mcps)
{
  // find number of MCPs within category
  for (auto mcp : mcps) {
    if (m_accept(mcp)) {
      ++m_naccept;
      ++m_naccept_per_event;
    }
  }
}

void Checker::TrackEffReport::operator()(
  const std::vector<MCAssociator::TrackWithWeight>& tracks,
  MCParticles::const_reference& mcp,
  const std::function<uint32_t(const MCParticle&)>& get_num_hits_subdetector)
{
  if (!m_accept(mcp)) return;

  ++m_nfound;
  ++m_nfound_per_event;
  bool found = false;
  for (const auto& track : tracks) {
    if (!found) {
      found = true;
    }
    else {
      ++m_nclones;
    }
    // update purity
    m_hitpur *= float(m_nfound + m_nclones - 1) / float(m_nfound + m_nclones);
    m_hitpur += track.m_w / float(m_nfound + m_nclones);
    // update hit efficiency
    auto hiteff = track.m_counter_subdetector / float(get_num_hits_subdetector(mcp));
    m_hiteff *= float(m_nfound + m_nclones - 1) / float(m_nfound + m_nclones);
    m_hiteff += hiteff / float(m_nfound + m_nclones);
  }
}

void Checker::TrackEffReport::report() const
{
  auto clonerate = 0.f, eff = 0.f, eff_per_event = 0.f;

  const float n_tot = float(m_nfound + m_nclones);
  if (m_nfound) clonerate = float(m_nclones) / n_tot;
  if (m_naccept) eff = float(m_nfound) / float(m_naccept);
  if (m_number_of_events) eff_per_event = ((float) m_eff_per_event) / ((float) m_number_of_events);

  if (m_naccept > 0) {
    std::printf(
      "%-50s: %9lu/%9lu %6.2f%% (%6.2f%%), "
      "%9lu (%6.2f%%) clones, pur %6.2f%%, hit eff %6.2f%%\n",
      m_name.c_str(),
      m_nfound,
      m_naccept,
      100 * static_cast<double>(eff),
      100 * static_cast<double>(eff_per_event),
      m_nclones,
      100 * static_cast<double>(clonerate),
      100 * static_cast<double>(m_hitpur),
      100 * static_cast<double>(m_hiteff));
  }
}
