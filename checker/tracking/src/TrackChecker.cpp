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
#include "TrackCheckerHistos.h"
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

// Not very pretty, will be better once nvcc supports C++17
std::string const Checker::Subdetector::Velo::name = "Velo";
std::string const Checker::Subdetector::UT::name = "VeloUT";
std::string const Checker::Subdetector::SciFi::name = "Forward";

TrackChecker::TrackChecker(
  std::string name,
  std::vector<Checker::TrackEffReport> categories,
  std::vector<Checker::HistoCategory> histo_categories,
  CheckerInvoker const* invoker,
  std::string const& root_file,
  std::string const& directory,
  bool print) :
  m_print {print},
  m_categories {std::move(categories)}, m_histo_categories {std::move(histo_categories)}, m_trackerName {
                                                                                            std::move(name)}
{
  // FIXME: Need to use a forward declaration to keep all ROOT objects
  // out of headers that are compiled with CUDA until NVCC supports
  // C++17
  m_histos = new TrackCheckerHistos {invoker, root_file, directory, m_histo_categories};
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

std::tuple<bool, MCParticles::const_iterator> TrackChecker::match_track_to_MCPs(
  const MCAssociator& mc_assoc,
  const Checker::Tracks& tracks,
  const int i_track,
  std::unordered_map<uint32_t, std::vector<MCAssociator::TrackWithWeight>>& assoc_table)
{
  const auto& track = tracks[i_track];

  // Note: This code is based heavily on
  //       https://gitlab.cern.ch/lhcb/Rec/blob/master/Pr/PrMCTools/src/PrTrackAssociator.cpp
  //
  // check LHCbIDs for MC association
  Checker::TruthCounter total_counter;
  std::unordered_map<uint, Checker::TruthCounter> truth_counters;
  int n_meas = 0;

  const auto& ids = track.ids();
  for (const auto& id : ids) {
    if (lhcb_id::is_velo(id)) {
      n_meas++;
      total_counter.n_velo++;
      const auto it_vec = mc_assoc.find_ids(id);
      for (const auto it : it_vec) {
        truth_counters[it->second].n_velo++;
      }
    }
    else if (lhcb_id::is_ut(id)) {
      n_meas++;
      total_counter.n_ut++;
      const auto it_vec = mc_assoc.find_ids(id);
      for (const auto it : it_vec) {
        truth_counters[it->second].n_ut++;
      }
    }
    else if (lhcb_id::is_scifi(id)) {
      n_meas++;
      total_counter.n_scifi++;
      const auto it_vec = mc_assoc.find_ids(id);
      for (const auto it : it_vec) {
        truth_counters[it->second].n_scifi++;
      }
    }
    else {
      debug_cout << "ID not matched to any subdetector " << std::hex << id << std::dec << std::endl;
    }
  }

  // If the Track has total # Velo hits > 2 AND total # SciFi hits > 2, combine matching of mother and daughter
  // particles
  if ((total_counter.n_velo > 2) && (total_counter.n_scifi > 2)) {
    for (auto& id_counter_1 : truth_counters) {
      if ((id_counter_1.second).n_scifi == 0) continue;
      const int mother_key = (mc_assoc.m_mcps[id_counter_1.first]).motherKey;
      for (auto& id_counter_2 : truth_counters) {
        if (&id_counter_1 == &id_counter_2) continue;
        const int key = (mc_assoc.m_mcps[id_counter_2.first]).key;
        if (key == mother_key) {
          if ((id_counter_2.second).n_velo == 0) continue;
          // debug_cout << "\t Particle with key " << key << " and PID " << (mc_assoc.m_mcps[id_counter_1.first]).pid <<
          // " is daughter of particle with PID " << (mc_assoc.m_mcps[id_counter_2.first]).pid << std::endl;

          //== Daughter hits are added to mother.
          (id_counter_2.second).n_velo += (id_counter_1.second).n_velo;
          (id_counter_2.second).n_ut += (id_counter_1.second).n_ut;
          (id_counter_2.second).n_scifi += (id_counter_1.second).n_scifi;
          if ((id_counter_2.second).n_velo > total_counter.n_velo) (id_counter_2.second).n_velo = total_counter.n_velo;
          if ((id_counter_2.second).n_ut > total_counter.n_ut) (id_counter_2.second).n_ut = total_counter.n_ut;
          if ((id_counter_2.second).n_scifi > total_counter.n_scifi)
            (id_counter_2.second).n_scifi = total_counter.n_scifi;

          //== Mother hits overwrite Daughter hits
          (id_counter_1.second).n_velo = (id_counter_2.second).n_velo;
          (id_counter_1.second).n_ut = (id_counter_2.second).n_ut;
          (id_counter_1.second).n_scifi = (id_counter_2.second).n_scifi;
        }
      }
    }
  }

  bool match = false;
  auto track_best_matched_MCP = mc_assoc.m_mcps.cend();

  float max_weight = 1e9f;
  for (const auto& id_counter : truth_counters) {
    bool velo_ok = true;
    bool scifi_ok = true;

    if (total_counter.n_velo > 2) {
      const auto weight = id_counter.second.n_velo / ((float) total_counter.n_velo);
      velo_ok = weight >= m_minweight;
    }
    if (total_counter.n_scifi > 2) {
      const auto weight = id_counter.second.n_scifi / ((float) total_counter.n_scifi);
      scifi_ok = weight >= m_minweight;
    }
    const bool ut_ok =
      (id_counter.second.n_ut + 2 > total_counter.n_ut) || (total_counter.n_velo > 2 && total_counter.n_scifi > 2);
    const auto counter_sum = id_counter.second.n_velo + id_counter.second.n_ut + id_counter.second.n_scifi;
    // Decision
    if (velo_ok && ut_ok && scifi_ok && n_meas > 0) {
      // debug_cout << "\t Matched track " << i_track << " to MCP " << (mc_assoc.m_mcps[id_counter.first]).key <<
      // std::endl;
      // save matched hits per subdetector
      // -> needed for hit efficiency
      int subdetector_counter = 0;
      if (m_trackerName == "Velo")
        subdetector_counter = id_counter.second.n_velo;
      else if (m_trackerName == "VeloUT")
        subdetector_counter = id_counter.second.n_ut;
      else if (m_trackerName == "Forward")
        subdetector_counter = id_counter.second.n_scifi;
      const float weight = ((float) counter_sum) / ((float) n_meas);
      const MCAssociator::TrackWithWeight track_weight = {i_track, weight, subdetector_counter};
      assoc_table[(mc_assoc.m_mcps[id_counter.first]).key].push_back(track_weight);
      match = true;

      if (weight < max_weight) {
        max_weight = weight;
        track_best_matched_MCP = mc_assoc.m_mcps.begin() + id_counter.first;
      }
    }
  }

  // if (total_counter.n_scifi > 2) {
  //   if (match) {
  //     std::ofstream ofs_xchi2;
  //     ofs_xchi2.open("good_combined_chi2.txt", std::ofstream::out | std::ofstream::app);
  //     ofs_xchi2 << track.qop << ", ";
  //     ofs_xchi2.close();
  //   } else {
  //     std::ofstream ofs_xchi2;
  //     ofs_xchi2.open("bad_combined_chi2.txt", std::ofstream::out | std::ofstream::app);
  //     ofs_xchi2 << track.qop << ", ";
  //     ofs_xchi2.close();
  //   }
  // }

  return {match, track_best_matched_MCP};
}

void TrackChecker::operator()(
  const Checker::Tracks& tracks,
  const MCEvent& mc_event,
  const std::function<uint32_t(const MCParticle&)>& get_num_hits_subdetector)
{
  for (auto& report : m_categories) {
    report.event_start();
  }

  // register MC particles
  for (auto& report : m_categories) {
    report(mc_event.m_mcps);
  }

  // fill histograms of reconstructible MC particles in various categories
  for (auto& histo_cat : m_histo_categories) {
    m_histos->fillReconstructibleHistos(mc_event.m_mcps, histo_cat);
  }

  MCAssociator mc_assoc {mc_event.m_mcps};
  // linker table between MCParticles and matched tracks with weights
  std::unordered_map<uint32_t, std::vector<MCAssociator::TrackWithWeight>> assoc_table;

  // Match tracks to MCPs
  std::size_t nghostsperevt = 0;
  std::size_t ntracksperevt = 0;
  std::size_t nghoststriggerperevt = 0;
  std::size_t ntrackstriggerperevt = 0;
  for (size_t i_track = 0; i_track < tracks.size(); ++i_track) {
    const auto& track = tracks[i_track];
    m_histos->fillTotalHistos(mc_event.m_mcps.empty() ? 0 : mc_event.m_mcps[0].nPV, static_cast<double>(track.eta));

    auto [match, track_best_matched_MCP] = match_track_to_MCPs(mc_assoc, tracks, i_track, assoc_table);

    ++ntracksperevt;

    const bool triggerCondition = track.p > 3000.f && track.pt > 500.f;
    if (triggerCondition) {
      ntrackstriggerperevt++;
    }
    if (!match) {
      ++nghostsperevt;
      m_histos->fillGhostHistos(mc_event.m_mcps.empty() ? 0 : mc_event.m_mcps[0].nPV, static_cast<double>(track.eta));
      if (triggerCondition) ++nghoststriggerperevt;
      if (track.is_muon) {
        m_histos->fillMuonGhostHistos(
          mc_event.m_mcps.empty() ? 0 : mc_event.m_mcps[0].nPV, static_cast<double>(track.eta));
        ++n_is_muon_ghost;
      }
    }
  }

  // Iterator over MCPs
  // Check which ones were matched to a track
  for (const auto mcp : mc_event.m_mcps) {
    const auto key = mcp.key;

    // Muon stats
    if (std::abs(mcp.pid) == 13) // muon
      m_n_MCPs_muon++;
    else // not muon
      m_n_MCPs_not_muon++;

    auto tracks_it = assoc_table.find(key);
    if (tracks_it == assoc_table.end()) // no track matched to MCP
      continue;

    m_n_tracks_matched_to_MCP++;

    // have MC association
    // find track with highest weight
    auto const& matched_tracks = tracks_it->second;
    auto track_with_weight = std::max_element(
      matched_tracks.cbegin(), matched_tracks.cend(), [
      ](const MCAssociator::TrackWithWeight& a, const MCAssociator::TrackWithWeight& b) noexcept {
        return a.m_w < b.m_w;
      });

    auto const& track = tracks[track_with_weight->m_idx];

    // add to various categories
    for (auto& report : m_categories) {
      // report(track, mcp, weight, get_num_hits);
      report(matched_tracks, mcp, get_num_hits_subdetector);
    }

    // Muon ID checker
    muon_id_matching(matched_tracks, mcp, tracks);

    // fill histograms of reconstructible MC particles in various categories
    for (auto& histo_cat : m_histo_categories) {
      m_histos->fillReconstructedHistos(mcp, histo_cat);
    }
    // fill histogram of momentum resolution
    if (m_trackerName == "Forward" && mcp.hasVelo && mcp.hasUT && mcp.hasSciFi) {
      m_histos->fillMomentumResolutionHisto(mcp, track.p, track.qop);
    }
    if (m_trackerName == "VeloUT" && mcp.hasVelo && mcp.hasUT) {
      m_histos->fillMomentumResolutionHisto(mcp, track.p, track.qop);
    }
  }

  for (auto& report : m_categories) {
    report.event_done();
  }

  // almost done, notify of end of event...
  ++m_nevents;

  m_ghostperevent *= float(m_nevents - 1) / float(m_nevents);
  if (ntracksperevt) {
    m_ghostperevent += (float(nghostsperevt) / float(ntracksperevt)) / float(m_nevents);
  }
  m_nghosts += nghostsperevt;
  m_ntracks += ntracksperevt;

  m_ghosttriggerperevent *= float(m_nevents - 1) / float(m_nevents);
  if (ntrackstriggerperevt) {
    m_ghosttriggerperevent += (float(nghoststriggerperevt) / float(ntrackstriggerperevt)) / float(m_nevents);
  }
  m_nghoststrigger += nghoststriggerperevt;
  m_ntrackstrigger += ntrackstriggerperevt;
}

TrackCheckerVelo::TrackCheckerVelo(CheckerInvoker const* invoker, std::string const& root_file) :
  TrackChecker {subdetector_t::name, Categories::Velo, Categories::VeloHisto, invoker, root_file, subdetector_t::name}
{}

TrackCheckerVeloUT::TrackCheckerVeloUT(CheckerInvoker const* invoker, std::string const& root_file) :
  TrackChecker {subdetector_t::name, Categories::VeloUT, Categories::VeloUTHisto, invoker, root_file, "Upstream"}
{}

TrackCheckerForward::TrackCheckerForward(CheckerInvoker const* invoker, std::string const& root_file) :
  TrackChecker {subdetector_t::name,
                Categories::Forward,
                Categories::ForwardHisto,
                invoker,
                root_file,
                subdetector_t::name,
                true}
{}
