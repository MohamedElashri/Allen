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

TrackChecker::TrackChecker(
  std::string name,
  std::vector<Checker::TrackEffReport> categories,
  std::vector<Checker::HistoCategory> histo_categories,
  CheckerInvoker const* invoker,
  std::string const& root_file,
  bool print) :
  m_print {print},
  m_categories {std::move(categories)}, m_histo_categories {std::move(histo_categories)}, m_trackerName {
                                                                                            std::move(name)}
{
  // FIXME: Need to use a forward declaration to keep all ROOT objects
  // out of headers that are compiled with CUDA until NVCC supports
  // C++17
  m_histos = new TrackCheckerHistos {invoker, root_file, name, m_histo_categories};
}

TrackChecker::~TrackChecker() { delete m_histos; }

void TrackChecker::report(size_t) const
{
  std::printf(
    "%-50s: %9lu/%9lu %6.2f%% ghosts\n",
    "TrackChecker output",
    m_nghosts,
    m_ntracks,
    (100.0 * static_cast<double>(m_nghosts)) / (static_cast<double>(m_ntracks)));

  if (m_trackerName == "Forward") {
    std::printf(
      "%-50s: %9lu/%9lu %6.2f%% ghosts\n",
      "for P>3GeV,Pt>0.5GeV",
      m_nghoststrigger,
      m_ntrackstrigger,
      100.0 * static_cast<double>(m_nghoststrigger) / static_cast<double>(m_ntrackstrigger));
  }

  for (auto const& report : m_categories) {
    report.report();
  }

  if (m_trackerName == "Forward") {
    if (n_matched_muons > 0 || n_matched_not_muons > 0 || m_nghosts > 0) {
      std::printf("\n\nMuon matching:\n");
    }
    if (n_matched_muons > 0) {
      // std::printf("Total number of tracks matched to an MCP = %lu, non muon MCPs = %lu, muon MCPs = %lu, total = %lu
      // \n", m_n_tracks_matched_to_MCP, n_matched_not_muons, n_matched_muons, n_matched_muons+n_matched_not_muons);
      std::printf(
        "Muon fraction in all MCPs:                                          %9lu/%9lu %6.2f%% \n",
        m_n_MCPs_muon,
        m_n_MCPs_not_muon + m_n_MCPs_muon,
        static_cast<double>(m_n_MCPs_muon) / (m_n_MCPs_not_muon + m_n_MCPs_muon));
      std::printf(
        "Muon fraction in MCPs to which a track(s) was matched:              %9lu/%9lu %6.2f%% \n",
        n_matched_muons,
        n_matched_muons + n_matched_not_muons,
        static_cast<double>(n_matched_muons) / (n_matched_muons + n_matched_not_muons));
      std::printf(
        "Correctly identified muons with isMuon:                             %9lu/%9lu %6.2f%% \n",
        n_is_muon_true,
        n_matched_muons,
        100 * static_cast<double>(n_is_muon_true) / static_cast<double>(n_matched_muons));
      std::printf(
        "Correctly identified muons from strange decays with isMuon:         %9lu/%9lu %6.2f%% \n",
        n_is_muon_true_fromS,
        n_matched_muons_fromS,
        100 * static_cast<double>(n_is_muon_true_fromS) / static_cast<double>(n_matched_muons_fromS));
      std::printf(
        "Correctly identified muons from B decays with isMuon:               %9lu/%9lu %6.2f%% \n",
        n_is_muon_true_fromB,
        n_matched_muons_fromB,
        100 * static_cast<double>(n_is_muon_true_fromB) / static_cast<double>(n_matched_muons_fromB));
    }
    if (n_matched_not_muons > 0) {
      std::printf(
        "Tracks identified as muon with isMuon, but matched to non-muon MCP: %9lu/%9lu %6.2f%% \n",
        n_is_muon_misID,
        n_matched_not_muons,
        100 * static_cast<double>(n_is_muon_misID) / static_cast<double>(n_matched_not_muons));
    }
    if (m_nghosts > 0) {
      std::printf(
        "Ghost tracks identified as muon with isMuon:                        %9lu/%9lu %6.2f%% \n",
        n_is_muon_ghost,
        m_nghosts,
        100 * static_cast<double>(n_is_muon_ghost) / static_cast<double>(m_nghosts));
    }
  }
  printf("\n");

  // write histograms to file
#ifdef WITH_ROOT
  m_histos->write();
#endif
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

void TrackChecker::muon_id_matching(
  const std::vector<MCAssociator::TrackWithWeight> tracks_with_weight,
  MCParticles::const_reference& mcp,
  const Checker::Tracks& tracks)
{

  if (m_trackerName == "Forward") {

    m_histos->fillMuonReconstructible(mcp);

    bool match_is_muon = false;

    for (const auto& track_with_weight : tracks_with_weight) {
      const int track_index = track_with_weight.m_idx;
      const Checker::Track& track = tracks[track_index];
      if (track.is_muon) {
        match_is_muon = true;
      }
    }
    // Correctly identified muons
    if (std::abs(mcp.pid) == 13) {
      n_matched_muons++;
      if (match_is_muon) {
        n_is_muon_true++;
        m_histos->fillMuonReconstructedMatchedIsMuon(mcp);
      }
    }
    // Correctly identified muons from strange decays
    if (std::abs(mcp.pid) == 13 && mcp.fromStrangeDecay) {
      n_matched_muons_fromS++;
      if (match_is_muon) {
        n_is_muon_true_fromS++;
        m_histos->fillMuonFromSReconstructedMatchedIsMuon(mcp);
      }
    }
    // Correctly identified muons from b decays
    if (std::abs(mcp.pid) == 13 && mcp.fromBeautyDecay) {
      n_matched_muons_fromB++;
      if (match_is_muon) {
        n_is_muon_true_fromB++;
        m_histos->fillMuonFromBReconstructedMatchedIsMuon(mcp);
      }
    }
    // Track identified as muon, but was matched to non-muon MCP
    else if (std::abs(mcp.pid) != 13) {
      n_matched_not_muons++;
      if (match_is_muon) {
        n_is_muon_misID++;
        m_histos->fillMuonReconstructedNotMatchedIsMuon(mcp);
      }
    }

    // fill muon ID histograms
    const Checker::Track& track = tracks[tracks_with_weight.front().m_idx];
    m_histos->fillMuonIDMatchedHistos(track, mcp);
  }
}

TrackCheckerVelo::TrackCheckerVelo(CheckerInvoker const* invoker, std::string const& root_file, const std::string& name) :
  TrackChecker {name, Categories::Velo, Categories::VeloHisto, invoker, root_file}
{}

TrackCheckerVeloUT::TrackCheckerVeloUT(CheckerInvoker const* invoker, std::string const& root_file, const std::string& name) :
  TrackChecker {name, Categories::VeloUT, Categories::VeloUTHisto, invoker, root_file}
{}

TrackCheckerForward::TrackCheckerForward(CheckerInvoker const* invoker, std::string const& root_file, const std::string& name) :
  TrackChecker {name,
                Categories::Forward,
                Categories::ForwardHisto,
                invoker,
                root_file,
                true}
{}
