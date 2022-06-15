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

void Checker::TrackEffReport::event_start()
{
  m_naccept_per_event = 0;
  m_nfound_per_event = 0;
}

void Checker::TrackEffReport::event_done()
{
  if (m_naccept_per_event) {
    m_number_of_events++;
    const double eff = double(m_nfound_per_event) / double(m_naccept_per_event);
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
    m_hitpurs.push_back(static_cast<double>(track.m_w));
    // update hit efficiency
    auto hiteff = track.m_counter_subdetector / static_cast<double>(get_num_hits_subdetector(mcp));
    m_hiteffs.push_back(hiteff);
  }
}

void Checker::TrackEffReport::report() const
{
  double clonerate = 0.0, eff = 0.0, eff_per_event = 0.0;

  const double n_tot = m_nfound + m_nclones;
  if (m_nfound) clonerate = double(m_nclones) / n_tot;
  if (m_naccept) eff = double(m_nfound) / double(m_naccept);
  if (m_number_of_events) eff_per_event = m_eff_per_event / m_number_of_events;

  if (m_naccept > 0) {
    auto hitpur = std::accumulate(std::begin(m_hitpurs), std::end(m_hitpurs), 0.0) / (m_nfound + m_nclones);
    auto hiteff = std::accumulate(std::begin(m_hiteffs), std::end(m_hiteffs), 0.0) / (m_nfound + m_nclones);
    std::printf(
      "%-50s: %9lu/%9lu %6.2f%% (%6.2f%%), "
      "%9lu (%6.2f%%) clones, pur %6.2f%%, hit eff %6.2f%%\n",
      m_name.c_str(),
      m_nfound,
      m_naccept,
      100 * eff,
      100 * eff_per_event,
      m_nclones,
      100 * clonerate,
      100 * hitpur,
      100 * hiteff);
  }
}
