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

TrackChecker::TrackChecker(std::string name, std::vector<Checker::TrackEffReport> categories,
                           std::vector<Checker::HistoCategory> histo_categories, bool create_file,
                           bool print)
  : m_print{print},
    m_categories{std::move(categories)},
    m_histo_categories{std::move(histo_categories)},
    m_trackerName{std::move(name)},
    m_create_file{create_file}
{
  // Need to use a forward declaration to keep all ROOT objects out of
  // headers that are compiled with CUDA
  histos = new TrackCheckerHistos{m_histo_categories};
}

TrackChecker::~TrackChecker()
{
  if (m_trackerName == "Forward") {
    if ( n_matched_muons > 0 ) {
      std::printf("\nMuon matching checker \n");
      std::printf(
        "Correctly identified muons with isMuon: \t \t \t \t %9lu/%9lu %6.2f%% \n",
        n_is_muon_true,
        n_matched_muons,
        100.f * float(n_is_muon_true) / float(n_matched_muons));
    }
    if ( n_matched_not_muons > 0 ) {
      std::printf(
        "Tracks identified as muon with isMuon, but matched to non-muon MCP: \t %9lu/%9lu %6.2f%% \n",
        n_is_muon_misID,
        n_matched_not_muons,
        100.f * float(n_is_muon_misID) / float(n_matched_not_muons));
    }
    if ( m_nghosts > 0 ) {
      std::printf(
        "Ghost tracks identified as muon with isMuon: \t \t \t \t %9lu/%9lu %6.2f%% \n",
        n_is_muon_ghost,
        m_nghosts,
        100.f * float(n_is_muon_ghost) / float(m_nghosts));
    }
  }  
  printf("\n");
    
  std::printf(
    "%-50s: %9lu/%9lu %6.2f%% ghosts\n",
    "TrackChecker output",
    m_nghosts,
    m_ntracks,
    100.f * float(m_nghosts) / float(m_ntracks));
  if (m_trackerName == "Forward") {
    std::printf(
      "%-50s: %9lu/%9lu %6.2f%% ghosts\n",
      "for P>3GeV,Pt>0.5GeV",
      m_nghoststrigger,
      m_ntrackstrigger,
      100.f * float(m_nghoststrigger) / float(m_ntrackstrigger));
  }
  m_categories.clear();
  std::printf("\n");

  // write histograms to file
#ifdef WITH_ROOT
  const std::string name = "../output/PrCheckerPlots.root";
  TFile f{name.c_str(), (m_create_file ? "RECREATE" : "UPDATE")};
  std::string dirName = m_trackerName;
  if (m_trackerName == "VeloUT") dirName = "Upstream";
  TDirectory* trackerDir = f.mkdir(dirName.c_str());
  trackerDir->cd();

  histos->write(trackerDir);

  f.Write();
  f.Close();

  delete histos;
#endif
}

void Checker::TrackEffReport::event_start() {
  m_naccept_per_event = 0;
  m_nfound_per_event = 0;
}

void Checker::TrackEffReport::event_done() {
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
  const std::vector<MCAssociator::TrackWithWeight> tracks,
  MCParticles::const_reference& mcp,
  const std::function<uint32_t(const MCParticle&)>& get_num_hits_subdetector)
{
  if (!m_accept(mcp)) return;

  ++m_nfound;
  ++m_nfound_per_event;
  bool found = false;
  int n_matched_total;
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

Checker::TrackEffReport::~TrackEffReport()
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
      100.f * eff,
      100.f * eff_per_event,
      m_nclones,
      100.f * clonerate,
      100.f * m_hitpur,
      100.f * m_hiteff);
  }
}

void TrackChecker::muon_id_matching(
  const std::vector<MCAssociator::TrackWithWeight> tracks_with_weight,
  MCParticles::const_reference& mcp,
  const Checker::Tracks& tracks) {

  if (m_trackerName == "Forward") {
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
      if ( match_is_muon )
        n_is_muon_true++;
    }
    // Track identified as muon, but was matched to non-muon MCP
    else if ( std::abs(mcp.pid) != 13) {
      n_matched_not_muons++;
      if ( match_is_muon )
        n_is_muon_misID++;
    }
  }
}

bool TrackChecker::match_track_to_MCPs(
  MCAssociator mc_assoc,
  const Checker::Tracks& tracks,
  const int i_track,
  std::map<uint32_t, std::vector<MCAssociator::TrackWithWeight>>& assoc_table,
  uint32_t& track_best_matched_MCP)
{
  const auto& track = tracks[i_track];

  // Note: This code is based heavily on
  //       https://gitlab.cern.ch/lhcb/Rec/blob/master/Pr/PrMCTools/src/PrTrackAssociator.cpp
  //
  // check LHCbIDs for MC association
  Checker::TruthCounter total_counter;
  std::map<uint, Checker::TruthCounter> truth_counters;
  int n_meas = 0;

  const auto& ids = track.ids();
  for (const auto& id : ids) {
    if (id.isVelo()) {
      n_meas++;
      total_counter.n_velo++;
      const auto it_vec = mc_assoc.find_ids(id);
      for (const auto it : it_vec) {
        truth_counters[it->second].n_velo++;
      }
    }
    else if (id.isUT()) {
      n_meas++;
      total_counter.n_ut++;
      const auto it_vec = mc_assoc.find_ids(id);
      for (const auto it : it_vec) {
        truth_counters[it->second].n_ut++;
      }
    }
    else if (id.isSciFi()) {
      n_meas++;
      total_counter.n_scifi++;
      const auto it_vec = mc_assoc.find_ids(id);
      for (const auto it : it_vec) {
        truth_counters[it->second].n_scifi++;
      }
    }
    else {
      debug_cout << "ID not matched to any subdetector" << std::endl;
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
      const MCAssociator::TrackWithWeight track_weight = {
        i_track, weight, subdetector_counter};
      assoc_table[(mc_assoc.m_mcps[id_counter.first]).key].push_back(track_weight);
      match = true;

      if ( weight < max_weight ) {
        max_weight = weight;
        track_best_matched_MCP = (mc_assoc.m_mcps[id_counter.first]).key;
      }
    }
  }

  return match;
}

std::vector<uint32_t> TrackChecker::operator()(
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
    histos->fillReconstructibleHistos(mc_event.m_mcps, histo_cat);
  }

  MCAssociator mc_assoc {mc_event.m_mcps};
  // linker table between MCParticles and matched tracks with weights
  std::map<uint32_t, std::vector<MCAssociator::TrackWithWeight>> assoc_table;

  // Match tracks to MCPs
  std::size_t nghostsperevt = 0;
  std::size_t ntracksperevt = 0;
  std::size_t nghoststriggerperevt = 0;
  std::size_t ntrackstriggerperevt = 0;
  std::vector<uint32_t> matched_mcp_keys;
  for (int i_track = 0; i_track < tracks.size(); ++i_track) {
    auto track = tracks[i_track];
    histos->fillTotalHistos(mc_event.m_mcps[0]);

    uint32_t track_best_matched_MCP;
    bool match = match_track_to_MCPs(mc_assoc, tracks, i_track, assoc_table, track_best_matched_MCP);

    if ( match ) {
      matched_mcp_keys.push_back(track_best_matched_MCP);
    }
    else {
      matched_mcp_keys.push_back(0xFFFFFFFF);
    }

    bool eta25 = track.eta > 2.f && track.eta < 5.f;
    bool skipEtaCut = (m_trackerName == "Velo");
    bool eta25Cut = eta25 | skipEtaCut;

    if (!eta25Cut) continue;
    ++ntracksperevt;

    const bool triggerCondition = track.p > 3000.f && track.pt > 500.f;
    if (triggerCondition) {
      ntrackstriggerperevt++;
    }
    if (!match) {
      ++nghostsperevt;
      histos->fillGhostHistos(mc_event.m_mcps[0]);
      if (triggerCondition) ++nghoststriggerperevt;
      if (track.is_muon) ++n_is_muon_ghost;
    }
  }

  // Iterator over MCPs
  // Check which ones were matched to a track
  for (const auto mcp : mc_event.m_mcps) {
    const auto key = mcp.key;

    if (assoc_table.find(key) == assoc_table.end()) // no track matched to MCP
      continue;

    // have MC association
    // find track with highest weight
    auto matched_tracks = assoc_table[key];
    std::sort(matched_tracks.begin(), matched_tracks.end(), [
    ](const MCAssociator::TrackWithWeight& a, const MCAssociator::TrackWithWeight& b) noexcept {
      return a.m_w > b.m_w;
    });

    const auto track_with_weight = matched_tracks.front();
    const auto weight = track_with_weight.m_w;
    auto track = tracks[track_with_weight.m_idx];

    // add to various categories
    for (auto& report : m_categories) {
      // report(track, mcp, weight, get_num_hits);
      report(matched_tracks, mcp, get_num_hits_subdetector);
    }

    // Muon ID checker
    muon_id_matching(matched_tracks, mcp, tracks);
    
    // fill histograms of reconstructible MC particles in various categories
    for (auto& histo_cat : m_histo_categories) {
      histos->fillReconstructedHistos(mcp, histo_cat);
    }
    // fill histogram of momentum resolution
    histos->fillMomentumResolutionHisto(mcp, track.p, track.qop);
    // fill muon ID histograms
    histos->fillMuonIDMatchedHistos(track, mcp);
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

  return matched_mcp_keys;
}

TrackCheckerVelo::TrackCheckerVelo(bool cf)
  : TrackChecker{"Velo", Categories::Velo, Categories::VeloHisto, cf} {}

TrackCheckerVeloUT::TrackCheckerVeloUT(bool cf)
  : TrackChecker{"VeloUT", Categories::VeloUT, Categories::VeloUTHisto, cf} {}

TrackCheckerForward::TrackCheckerForward(bool cf)
  : TrackChecker{"Forward", Categories::Forward, Categories::ForwardHisto, cf, true} {}
