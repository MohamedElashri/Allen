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
 */

#include <cstdio>

#include "TrackChecker.h"

TrackChecker::~TrackChecker()
{
  std::printf(
    "%-50s: %9lu/%9lu %6.2f%% (%6.2f%%) ghosts\n",
    "TrackChecker output",
    m_nghosts,
    m_ntracks,
    100.f * float(m_nghosts) / float(m_ntracks),
    100.f * m_ghostperevent);
  m_categories.clear();
  std::printf("\n");

  // write histograms to file
#ifdef WITH_ROOT
  const std::string name = "../output/PrCheckerPlots.root";
  TFile* f = new TFile(name.c_str(), "UPDATE");
  std::string dirName = m_trackerName;
  if (m_trackerName == "VeloUT") dirName = "Upstream";
  TDirectory* trackerDir = f->mkdir(dirName.c_str());
  trackerDir->cd();
  histos.h_dp_versus_p->Write();
  histos.h_momentum_resolution->Write();
  histos.h_qop_resolution->Write();
  histos.h_dqop_versus_qop->Write();
  histos.h_momentum_matched->Write();
  for (auto histo : histos.h_reconstructible_eta)
    histo.second->Write();
  for (auto histo : histos.h_reconstructible_p)
    histo.second->Write();
  for (auto histo : histos.h_reconstructible_pt)
    histo.second->Write();
  for (auto histo : histos.h_reconstructible_phi)
    histo.second->Write();
  for (auto histo : histos.h_reconstructible_nPV)
    histo.second->Write();
  for (auto histo : histos.h_reconstructed_eta)
    histo.second->Write();
  for (auto histo : histos.h_reconstructed_p)
    histo.second->Write();
  for (auto histo : histos.h_reconstructed_pt)
    histo.second->Write();
  for (auto histo : histos.h_reconstructed_phi)
    histo.second->Write();
  for (auto histo : histos.h_reconstructed_nPV)
    histo.second->Write();
  histos.h_ghost_nPV->Write();
  histos.h_total_nPV->Write();

  f->Write();
  f->Close();

  histos.deleteHistos(m_histo_categories);
#endif
}

void TrackChecker::TrackEffReport::operator()(const MCParticles& mcps)
{
  // find number of MCPs within category
  for (auto mcp : mcps) {
    if (m_accept(mcp)) {
      ++m_naccept;
      ++m_nacceptperevt;
    }
  }
}

void TrackChecker::TrackEffReport::operator()(
  const std::vector<MCAssociator::TrackWithWeight> tracks, 
  MCParticles::const_reference& mcp,
  const std::function<uint32_t(const MCParticle&)>& get_num_hits) 
{
  if (!m_accept(mcp)) return;
  
  ++m_nfound;
  ++m_nfoundperevt;
  
  bool found = false;
  float weight;
  int n_matched_total;
  for ( const auto& track : tracks ) {
    if ( !found ) {
      found = true;
      weight = track.m_w;
      n_matched_total = track.m_counter_sum;
    } else {
      ++m_nclones;
    }
  }
  if ( found ) {
    // update purity
    m_hitpur *= float(m_nfound + m_nclones - 1) / float(m_nfound + m_nclones);
    m_hitpur += weight / float(m_nfound + m_nclones);
    // update hit efficiency
    auto hiteff = n_matched_total / float(get_num_hits(mcp));
    m_hiteff *= float(m_nfound + m_nclones - 1) / float(m_nfound + m_nclones);
    m_hiteff += hiteff / float(m_nfound + m_nclones);
  }
}

void TrackChecker::TrackEffReport::evtEnds()
{
  m_keysseen.clear();
  if (m_nacceptperevt) {
    m_effperevt *= float(m_nevents) / float(m_nevents + 1);
    ++m_nevents;
    m_effperevt += (float(m_nfoundperevt) / float(m_nacceptperevt)) / float(m_nevents);
  }
  m_nfoundperevt = m_nacceptperevt = 0;
}

TrackChecker::TrackEffReport::~TrackEffReport()
{
  auto clonerate = 0.f, eff = 0.f;
  const float n_tot = float(m_nfound + m_nclones);
  if (m_nfound) clonerate = float(m_nclones) / n_tot; 
  if (m_naccept) eff = float(m_nfound) / float(m_naccept);

  if (m_naccept > 0) {
    std::printf(
      "%-50s: %9lu/%9lu %6.2f%% (%6.2f%%), "
      "%9lu (%6.2f%%) clones, pur %6.2f%%, hit eff %6.2f%%\n",
      m_name.c_str(),
      m_nfound,
      m_naccept,
      100.f * eff,
      100.f * m_effperevt,
      m_nclones,
      100.f * clonerate,
      100.f * m_hitpur,
      100.f * m_hiteff);
  }
}

void TrackChecker::HistoCategory::evtEnds() { m_keysseen.clear(); }

void TrackChecker::Histos::initHistos(const std::vector<HistoCategory>& histo_categories)
{
#ifdef WITH_ROOT
  // histos for efficiency
  for (auto histoCat : histo_categories) {
    const std::string& category = histoCat.m_name;
    std::string name = category + "_Eta_reconstructible";
    if (category.find("eta25") != std::string::npos) {
      h_reconstructible_eta[name] = new TH1D(name.c_str(), name.c_str(), 50, 0., 7.);
      name = category + "_Eta_reconstructed";
      h_reconstructed_eta[name] = new TH1D(name.c_str(), name.c_str(), 50, 0., 7.);
    }
    else {
      h_reconstructible_eta[name] = new TH1D(name.c_str(), name.c_str(), 100, -7., 7.);
      name = category + "_Eta_reconstructed";
      h_reconstructed_eta[name] = new TH1D(name.c_str(), name.c_str(), 100, -7., 7.);
    }
    name = category + "_P_reconstructible";
    h_reconstructible_p[name] = new TH1D(name.c_str(), name.c_str(), 50, 0., 100000.);
    name = category + "_Pt_reconstructible";
    h_reconstructible_pt[name] = new TH1D(name.c_str(), name.c_str(), 50, 0., 100000.);
    name = category + "_Phi_reconstructible";
    h_reconstructible_phi[name] = new TH1D(name.c_str(), name.c_str(), 25, -3.142, 3.142);
    name = category + "_nPV_reconstructible";
    h_reconstructible_nPV[name] = new TH1D(name.c_str(), name.c_str(), 21, -0.5, 20.5);
    name = category + "_P_reconstructed";
    h_reconstructed_p[name] = new TH1D(name.c_str(), name.c_str(), 50, 0., 100000.);
    name = category + "_Pt_reconstructed";
    h_reconstructed_pt[name] = new TH1D(name.c_str(), name.c_str(), 50, 0., 100000.);
    name = category + "_Phi_reconstructed";
    h_reconstructed_phi[name] = new TH1D(name.c_str(), name.c_str(), 25, -3.142, 3.142);
    name = category + "_nPV_reconstructed";
    h_reconstructed_nPV[name] = new TH1D(name.c_str(), name.c_str(), 21, -0.5, 20.5);
  }

  // histos for ghost rate
  h_ghost_nPV = new TH1D("nPV_Ghosts", "nPV_Ghosts", 21, -0.5, 20.5);
  h_total_nPV = new TH1D("nPV_Total", "nPV_Total", 21, -0.5, 20.5);

  // histo for momentum resolution
  h_momentum_resolution = new TH2D("momentum_resolution", "momentum resolution", 10, 0, 100000., 1000, -5., 5.);
  h_qop_resolution = new TH2D("qop_resolution", "qop resolution", 10, -0.2e-3, 0.2e-3, 1000, -5., 5.);
  h_dqop_versus_qop = new TH2D("dqop_vs_qop", "dqop vs. qop", 100, -0.2e-3, 0.2e-3, 100, -0.05e-3, 0.05e-3);
  h_dp_versus_p = new TH2D("dp_vs_p", "dp vs. p", 100, 0, 100000., 1000, -10000., 10000.);
  h_momentum_matched = new TH1D("p_matched", "p, matched", 100, 0, 100000.);
#endif
}

void TrackChecker::Histos::deleteHistos(const std::vector<HistoCategory>& histo_categories)
{
#ifdef WITH_ROOT
  for (auto histoCat : histo_categories) {
    const std::string& category = histoCat.m_name;
    std::string name = category + "_Eta_reconstructible";
    delete h_reconstructible_eta[name];
    name = category + "_Eta_reconstructed";
    delete h_reconstructed_eta[name];
    name = category + "_P_reconstructible";
    delete h_reconstructible_p[name];
    name = category + "_Pt_reconstructible";
    delete h_reconstructible_pt[name];
    name = category + "_Phi_reconstructible";
    delete h_reconstructible_phi[name];
    name = category + "_nPV_reconstructible";
    delete h_reconstructible_nPV[name];
    name = category + "_P_reconstructed";
    delete h_reconstructed_p[name];
    name = category + "_Pt_reconstructed";
    delete h_reconstructed_pt[name];
    name = category + "_Phi_reconstructed";
    delete h_reconstructed_phi[name];
    name = category + "_nPV_reconstructed";
    delete h_reconstructed_nPV[name];
  }
  delete h_ghost_nPV;
  delete h_total_nPV;
  delete h_dp_versus_p;
  delete h_momentum_resolution;
  delete h_qop_resolution;
  delete h_dqop_versus_qop;
  delete h_momentum_matched;
#endif
}

void TrackChecker::Histos::fillReconstructibleHistos(const MCParticles& mcps, const HistoCategory& category)
{
#ifdef WITH_ROOT
  const std::string eta_name = category.m_name + "_Eta_reconstructible";
  const std::string p_name = category.m_name + "_P_reconstructible";
  const std::string pt_name = category.m_name + "_Pt_reconstructible";
  const std::string phi_name = category.m_name + "_Phi_reconstructible";
  const std::string nPV_name = category.m_name + "_nPV_reconstructible";
  for (auto mcp : mcps) {
    if (category.m_accept(mcp)) {
      h_reconstructible_eta[eta_name]->Fill(mcp.eta);
      h_reconstructible_p[p_name]->Fill(mcp.p);
      h_reconstructible_pt[pt_name]->Fill(mcp.pt);
      h_reconstructible_phi[phi_name]->Fill(mcp.phi);
      h_reconstructible_nPV[nPV_name]->Fill(mcp.nPV);
    }
  }
#endif
}

void TrackChecker::Histos::fillReconstructedHistos(const MCParticle& mcp, HistoCategory& category)
{
#ifdef WITH_ROOT
  if (!(category.m_accept(mcp))) return;
  if ((category.m_keysseen).count(mcp.key)) return; // clone track
  (category.m_keysseen).insert(mcp.key);            // not clone track, mark as matched

  const std::string eta_name = category.m_name + "_Eta_reconstructed";
  const std::string p_name = category.m_name + "_P_reconstructed";
  const std::string pt_name = category.m_name + "_Pt_reconstructed";
  const std::string phi_name = category.m_name + "_Phi_reconstructed";
  const std::string nPV_name = category.m_name + "_nPV_reconstructed";
  h_reconstructed_eta[eta_name]->Fill(mcp.eta);
  h_reconstructed_p[p_name]->Fill(mcp.p);
  h_reconstructed_pt[pt_name]->Fill(mcp.pt);
  h_reconstructed_phi[phi_name]->Fill(mcp.phi);
  h_reconstructed_nPV[nPV_name]->Fill(mcp.nPV);
#endif
}

void TrackChecker::Histos::fillTotalHistos(const MCParticle& mcp)
{
#ifdef WITH_ROOT
  h_total_nPV->Fill(mcp.nPV);
#endif
}

void TrackChecker::Histos::fillGhostHistos(const MCParticle& mcp)
{
#ifdef WITH_ROOT
  h_ghost_nPV->Fill(mcp.nPV);
#endif
}

void TrackChecker::Histos::fillMomentumResolutionHisto(const MCParticle& mcp, const float p, const float qop)
{
#ifdef WITH_ROOT
  float mc_qop = mcp.charge / mcp.p;
  h_dp_versus_p->Fill(mcp.p, (mcp.p - p));
  h_momentum_resolution->Fill(mcp.p, (mcp.p - p) / mcp.p);
  h_qop_resolution->Fill(mc_qop, (mc_qop - qop) / mc_qop);
  h_dqop_versus_qop->Fill(mc_qop, mc_qop - qop);
  h_momentum_matched->Fill(mcp.p);
#endif
}

bool TrackChecker::match_track_to_MCPs(
  MCAssociator mc_assoc,
  const Checker::Tracks& tracks,
  const int i_track,
  std::map<uint32_t, std::vector<MCAssociator::TrackWithWeight> >& assoc_table) 
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
    if ( id.isVelo() ) {
      n_meas++;
      total_counter.n_velo++;
      const auto it_vec = mc_assoc.find_ids(id);
      for ( const auto it : it_vec ) {
        truth_counters[it->second].n_velo++;
      }
    }
    else if ( id.isUT() ) {
      n_meas++;
      total_counter.n_ut++;
      const auto it_vec = mc_assoc.find_ids(id);
      for ( const auto it : it_vec ) {
        truth_counters[it->second].n_ut++;
      }
    }
    else if ( id.isSciFi() ) {
      n_meas++;
      total_counter.n_scifi++;
      const auto it_vec = mc_assoc.find_ids(id);
      for ( const auto it : it_vec ) {
        truth_counters[it->second].n_scifi++;
      }
    }
    else {
      debug_cout << "ID not matched to any subdetector" << std::endl;
    }
  }
  
  // If the Track has total # Velo hits > 2 AND total # SciFi hits > 2, combine matching of mother and daughter particles
  if ( ( total_counter.n_velo > 2 ) && ( total_counter.n_scifi > 2 ) ) {
    for ( auto& id_counter_1 : truth_counters ) {
      if ( (id_counter_1.second).n_scifi == 0 ) continue; 
      const int mother_key = (mc_assoc.m_mcps[id_counter_1.first]).motherKey; 
      for ( auto& id_counter_2 : truth_counters ) {
        if ( &id_counter_1 == &id_counter_2 ) continue;
        const int key = (mc_assoc.m_mcps[id_counter_2.first]).key; 
        if ( key == mother_key ) {
          if ( (id_counter_2.second).n_velo == 0 ) continue; 
          debug_cout << "\t Particle with key " << key << " and PID " << (mc_assoc.m_mcps[id_counter_1.first]).pid << " is daughter of particle with PID " << (mc_assoc.m_mcps[id_counter_2.first]).pid << std::endl;
          
          //== Daughter hits are added to mother. 
          (id_counter_2.second).n_velo += (id_counter_1.second).n_velo;
          (id_counter_2.second).n_ut += (id_counter_1.second).n_ut;
          (id_counter_2.second).n_scifi += (id_counter_1.second).n_scifi;
          if ( (id_counter_2.second).n_velo > total_counter.n_velo ) 
            (id_counter_2.second).n_velo = total_counter.n_velo;
          if ( (id_counter_2.second).n_ut > total_counter.n_ut ) 
            (id_counter_2.second).n_ut = total_counter.n_ut;
          if ( (id_counter_2.second).n_scifi > total_counter.n_scifi ) 
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
      debug_cout << "\t Matched track " << i_track << " to MCP " << (mc_assoc.m_mcps[id_counter.first]).key << std::endl; 
      const MCAssociator::TrackWithWeight track_weight = {i_track, ((float) counter_sum) / ((float) n_meas), counter_sum};
      assoc_table[ (mc_assoc.m_mcps[id_counter.first]).key ].push_back( track_weight );
      match = true;
    }
  } 

  return match;
}

std::vector<uint32_t> TrackChecker::operator()(const Checker::Tracks& tracks, const MCEvent& mc_event,
  const std::function<uint32_t(const MCParticle&)>& get_num_hits)
{
  // register MC particles
  for (auto& report : m_categories) {
    report(mc_event.m_mcps);
  }

  // fill histograms of reconstructible MC particles in various categories
  for (auto& histo_cat : m_histo_categories) {
    histos.fillReconstructibleHistos(mc_event.m_mcps, histo_cat);
  }

  MCAssociator mc_assoc {mc_event.m_mcps};
  // linker table between MCParticles and matched tracks with weights
  std::map<uint32_t, std::vector<MCAssociator::TrackWithWeight> > assoc_table;

  // Match tracks to MCPs
  const std::size_t ntracksperevt = tracks.size();
  std::size_t nghostsperevt = 0;
  std::vector<uint32_t> matched_mcp_keys;
  for ( int i_track = 0; i_track < tracks.size(); ++i_track ) {
    auto track = tracks[i_track];
    histos.fillTotalHistos(mc_event.m_mcps[0]);

    bool match = match_track_to_MCPs(mc_assoc, tracks, i_track, assoc_table);
   
    if ( !match ) {
      ++nghostsperevt;
      histos.fillGhostHistos(mc_event.m_mcps[0]);
      matched_mcp_keys.push_back(0xFFFFFFFF);
    }
    
  } 
  
  // Iterator over MCPs
  // Check which ones were matched to a track
  for ( const auto mcp : mc_event.m_mcps ) {
    const auto key = mcp.key;
    
    if ( assoc_table.find(key) == assoc_table.end() ) // no track matched to MCP
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
    //track.n_matched_total = track_with_weight.m_counter_sum;
    
    // add to various categories
    for (auto& report : m_categories) {
      //report(track, mcp, weight, get_num_hits);
      report(matched_tracks, mcp, get_num_hits);
    }
    // write out matched MCP key
    matched_mcp_keys.push_back(key);

    // fill histograms of reconstructible MC particles in various categories
    for (auto& histo_cat : m_histo_categories) {
      histos.fillReconstructedHistos(mcp, histo_cat);
    }
    // fill histogram of momentum resolution
    histos.fillMomentumResolutionHisto(mcp, track.p, track.qop);
  }
  // almost done, notify of end of event...
  ++m_nevents;
  for (auto& report : m_categories) {
    report.evtEnds();
  }

  for (auto& histo_cat : m_histo_categories)
    histo_cat.evtEnds();
  m_ghostperevent *= float(m_nevents - 1) / float(m_nevents);
  if (ntracksperevt) {
    m_ghostperevent += (float(nghostsperevt) / float(ntracksperevt)) / float(m_nevents);
  }
  m_nghosts += nghostsperevt;
  m_ntracks += ntracksperevt;

  return matched_mcp_keys;
}
