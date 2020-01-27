#include "SelCheckerTuple.h"
#include <ROOTHeaders.h>

std::string const SelCheckerTuple::SelTupleTag::name = "SelCheckerTuple";

#ifdef WITH_ROOT
SelCheckerTuple::SelCheckerTuple(CheckerInvoker const* invoker, std::string const& root_file)
{
  m_file = invoker->root_file(root_file);
  m_file->cd();
  m_tree = new TTree("eff_tree", "eff_tree");
  m_tree->Branch("event_pass_gec", &m_event_pass_gec);
  m_tree->Branch("gen_key", &m_gen_key);
  m_tree->Branch("gen_pid", &m_gen_pid);
  m_tree->Branch("gen_p", &m_gen_p);
  m_tree->Branch("gen_pt", &m_gen_pt);
  m_tree->Branch("gen_eta", &m_gen_eta);
  m_tree->Branch("gen_phi", &m_gen_phi);
  m_tree->Branch("gen_tau", &m_gen_tau);
  m_tree->Branch("gen_ovtx_x", &m_gen_ovtx_x);
  m_tree->Branch("gen_ovtx_y", &m_gen_ovtx_y);
  m_tree->Branch("gen_ovtx_z", &m_gen_ovtx_z);
  m_tree->Branch("gen_long", &m_gen_long);
  m_tree->Branch("gen_down", &m_gen_down);
  m_tree->Branch("gen_has_velo", &m_gen_has_velo);
  m_tree->Branch("gen_has_ut", &m_gen_has_ut);
  m_tree->Branch("gen_has_scifi", &m_gen_has_scifi);
  m_tree->Branch("gen_from_b", &m_gen_from_b);
  m_tree->Branch("gen_from_c", &m_gen_from_c);
  m_tree->Branch("gen_from_s", &m_gen_from_s);
  m_tree->Branch("gen_mom_key", &m_gen_mom_key);
  m_tree->Branch("gen_decmom_key", &m_gen_decmom_key);
  m_tree->Branch("gen_decmom_pid", &m_gen_decmom_pid);
  m_tree->Branch("gen_decmom_tau", &m_gen_decmom_tau);
  m_tree->Branch("gen_decmom_pt", &m_gen_decmom_pt);
  m_tree->Branch("sv_px", &m_sv_px);
  m_tree->Branch("sv_py", &m_sv_py);
  m_tree->Branch("sv_pz", &m_sv_pz);
  m_tree->Branch("sv_x", &m_sv_x);
  m_tree->Branch("sv_y", &m_sv_y);
  m_tree->Branch("sv_z", &m_sv_z);
  m_tree->Branch("sv_cov00", &m_sv_cov00);
  m_tree->Branch("sv_cov10", &m_sv_cov10);
  m_tree->Branch("sv_cov11", &m_sv_cov11);
  m_tree->Branch("sv_cov20", &m_sv_cov20);
  m_tree->Branch("sv_cov21", &m_sv_cov21);
  m_tree->Branch("sv_cov22", &m_sv_cov22);
  m_tree->Branch("sv_sumpt", &m_sv_sumpt);
  m_tree->Branch("sv_fdchi2", &m_sv_fdchi2);
  m_tree->Branch("sv_mdimu", &m_sv_mdimu);
  m_tree->Branch("sv_mcor", &m_sv_mcor);
  m_tree->Branch("sv_eta", &m_sv_eta);
  m_tree->Branch("sv_minipchi2", &m_sv_minipchi2);
  m_tree->Branch("sv_minpt", &m_sv_minpt);
  m_tree->Branch("sv_ntrksassoc", &m_sv_ntrksassoc);
  m_tree->Branch("sv_idx_trk1", &m_sv_idx_trk1);
  m_tree->Branch("sv_idx_trk2", &m_sv_idx_trk2);
  for (uint i_line = Hlt1::startTwoTrackLines; i_line < Hlt1::startThreeTrackLines; i_line++) {
    std::string line_name = Hlt1::Hlt1LineNames[i_line];
    m_sv_decisions[line_name] = std::vector<double>();
    std::string branch_name = "sv_pass_" + line_name;
    m_tree->Branch(branch_name.c_str(), &m_sv_decisions[line_name]);
  }

  m_tree->Branch("trk_p", &m_trk_p);
  m_tree->Branch("trk_pt", &m_trk_pt);
  m_tree->Branch("trk_eta", &m_trk_eta);
  m_tree->Branch("trk_chi2", &m_trk_chi2);
  m_tree->Branch("trk_ndof", &m_trk_ndof);
  m_tree->Branch("trk_is_muon", &m_trk_is_muon);
  m_tree->Branch("trk_kalman_ip", &m_trk_kalman_ip);
  m_tree->Branch("trk_kalman_ipchi2", &m_trk_kalman_ipchi2);
  m_tree->Branch("trk_velo_ip", &m_trk_velo_ip);
  m_tree->Branch("trk_velo_ipchi2", &m_trk_velo_ipchi2);
  m_tree->Branch("trk_idx_gen", &m_trk_idx_gen);
  for (uint i_line = Hlt1::startOneTrackLines; i_line < Hlt1::startTwoTrackLines; i_line++) {
    std::string line_name = Hlt1::Hlt1LineNames[i_line];
    m_trk_decisions[line_name] = std::vector<double>();
    std::string branch_name = "trk_pass_" + line_name;
    m_tree->Branch(branch_name.c_str(), &m_trk_decisions[line_name]);
  }

#else
SelCheckerTuple::SelCheckerTuple(CheckerInvoker const*, std::string const&)
{
#endif
}

void SelCheckerTuple::clear()
{
  m_event_pass_gec.clear();
  m_gen_key.clear();
  m_gen_pid.clear();
  m_gen_p.clear();
  m_gen_pt.clear();
  m_gen_eta.clear();
  m_gen_phi.clear();
  m_gen_tau.clear();
  m_gen_ovtx_x.clear();
  m_gen_ovtx_y.clear();
  m_gen_ovtx_z.clear();
  m_gen_long.clear();
  m_gen_down.clear();
  m_gen_has_velo.clear();
  m_gen_has_ut.clear();
  m_gen_has_scifi.clear();
  m_gen_from_b.clear();
  m_gen_from_c.clear();
  m_gen_from_s.clear();
  m_gen_mom_key.clear();
  m_gen_decmom_key.clear();
  m_gen_decmom_pid.clear();
  m_gen_decmom_tau.clear();
  m_gen_decmom_pt.clear();
  m_sv_px.clear();
  m_sv_py.clear();
  m_sv_pz.clear();
  m_sv_x.clear();
  m_sv_y.clear();
  m_sv_z.clear();
  m_sv_cov00.clear();
  m_sv_cov10.clear();
  m_sv_cov11.clear();
  m_sv_cov20.clear();
  m_sv_cov21.clear();
  m_sv_cov22.clear();
  m_sv_sumpt.clear();
  m_sv_fdchi2.clear();
  m_sv_mdimu.clear();
  m_sv_mcor.clear();
  m_sv_eta.clear();
  m_sv_minipchi2.clear();
  m_sv_minpt.clear();
  m_sv_ntrksassoc.clear();
  m_sv_idx_trk1.clear();
  m_sv_idx_trk2.clear();
  for (uint i_line = Hlt1::startTwoTrackLines; i_line < Hlt1::startThreeTrackLines; i_line++) {
    std::string line_name = Hlt1::Hlt1LineNames[i_line];
    m_sv_decisions[line_name].clear();
  }

  m_trk_p.clear();
  m_trk_pt.clear();
  m_trk_eta.clear();
  m_trk_chi2.clear();
  m_trk_ndof.clear();
  m_trk_is_muon.clear();
  m_trk_kalman_ip.clear();
  m_trk_kalman_ipchi2.clear();
  m_trk_velo_ip.clear();
  m_trk_velo_ipchi2.clear();
  m_trk_idx_gen.clear();
  for (uint i_line = Hlt1::startOneTrackLines; i_line < Hlt1::startTwoTrackLines; i_line++) {
    std::string line_name = Hlt1::Hlt1LineNames[i_line];
    m_trk_decisions[line_name].clear();
  }
}

size_t SelCheckerTuple::addGen(const MCParticle& mcp)
{
  double key = mcp.key;
  for (size_t i = 0; i < m_gen_key.size(); ++i) {
    if (m_gen_key.at(i) == key) return i;
  }
  auto idx = m_gen_key.size();
  m_gen_key.push_back((double) mcp.key);
  m_gen_pid.push_back((double) mcp.pid);
  m_gen_p.push_back((double) mcp.p);
  m_gen_pt.push_back((double) mcp.pt);
  m_gen_eta.push_back((double) mcp.eta);
  m_gen_phi.push_back((double) mcp.phi);
  m_gen_ovtx_x.push_back((double) mcp.ovtx_x);
  m_gen_ovtx_y.push_back((double) mcp.ovtx_y);
  m_gen_ovtx_z.push_back((double) mcp.ovtx_z);
  m_gen_long.push_back(mcp.isLong ? 1. : 0.);
  m_gen_down.push_back(mcp.isDown ? 1. : 0.);
  m_gen_has_velo.push_back(mcp.hasVelo ? 1. : 0.);
  m_gen_has_ut.push_back(mcp.hasUT ? 1. : 0.);
  m_gen_has_scifi.push_back(mcp.hasSciFi ? 1. : 0.);
  m_gen_from_b.push_back(mcp.fromBeautyDecay ? 1. : 0.);
  m_gen_from_c.push_back(mcp.fromCharmDecay ? 1. : 0.);
  m_gen_from_s.push_back(mcp.fromStrangeDecay ? 1. : 0.);
  m_gen_mom_key.push_back((double) mcp.motherKey);
  m_gen_decmom_key.push_back((double) mcp.DecayOriginMother_key);
  m_gen_decmom_pid.push_back((double) mcp.DecayOriginMother_pid);
  m_gen_decmom_tau.push_back((double) mcp.DecayOriginMother_tau);
  m_gen_decmom_pt.push_back((double) mcp.DecayOriginMother_pt);
  return idx;
}

size_t SelCheckerTuple::addSV(const VertexFit::TrackMVAVertex& sv, const int idx1, const int idx2)
{
  for (size_t i = 0; i < m_sv_px.size(); ++i) {
    if (
      std::abs(m_sv_px.at(i) - static_cast<double>(sv.px)) < 0.01 &&
      std::abs(m_sv_py.at(i) - static_cast<double>(sv.py)) < 0.01 &&
      std::abs(m_sv_pz.at(i) - static_cast<double>(sv.pz)) < 0.01) {
      return i;
    }
  }
  size_t idx = m_sv_px.size();
  m_sv_px.push_back((double) sv.px);
  m_sv_py.push_back((double) sv.py);
  m_sv_pz.push_back((double) sv.pz);
  m_sv_x.push_back((double) sv.x);
  m_sv_y.push_back((double) sv.y);
  m_sv_z.push_back((double) sv.z);
  m_sv_cov00.push_back((double) sv.cov00);
  m_sv_cov10.push_back((double) sv.cov10);
  m_sv_cov11.push_back((double) sv.cov11);
  m_sv_cov20.push_back((double) sv.cov20);
  m_sv_cov21.push_back((double) sv.cov21);
  m_sv_cov22.push_back((double) sv.cov22);
  m_sv_sumpt.push_back((double) sv.sumpt);
  m_sv_fdchi2.push_back((double) sv.fdchi2);
  m_sv_mdimu.push_back((double) sv.mdimu);
  m_sv_mcor.push_back((double) sv.mcor);
  m_sv_eta.push_back((double) sv.eta);
  m_sv_minipchi2.push_back((double) sv.minipchi2);
  m_sv_minpt.push_back((double) sv.minpt);
  m_sv_ntrksassoc.push_back((double) sv.ntrksassoc);
  m_sv_idx_trk1.push_back((double) idx1);
  m_sv_idx_trk2.push_back((double) idx2);
  return idx;
}

size_t SelCheckerTuple::addTrack(Checker::Track& track, const MCAssociator& mcassoc)
{
  for (size_t i = 0; i < m_trk_p.size(); ++i) {
    if (
      std::abs(static_cast<double>(track.p) - m_trk_p.at(i)) < 0.01 &&
      std::abs(static_cast<double>(track.pt) - m_trk_pt.at(i)) < 0.01 &&
      std::abs(static_cast<double>(track.eta) - m_trk_eta.at(i)) < 0.01) {
      return i;
    }
  }
  size_t idx = m_trk_p.size();
  m_trk_p.push_back((double) track.p);
  m_trk_pt.push_back((double) track.pt);
  m_trk_eta.push_back((double) track.eta);
  m_trk_chi2.push_back((double) track.chi2);
  m_trk_ndof.push_back((double) track.ndof);
  m_trk_is_muon.push_back(track.is_muon ? 1. : 0.);
  m_trk_kalman_ip.push_back((double) track.kalman_ip);
  m_trk_kalman_ipchi2.push_back((double) track.kalman_ip_chi2);
  m_trk_velo_ip.push_back((double) track.velo_ip);
  m_trk_velo_ipchi2.push_back((double) track.velo_ip_chi2);
  const auto& ids = track.ids();
  const auto assoc = mcassoc(ids.begin(), ids.end(), track.n_matched_total);
  if (!assoc)
    m_trk_idx_gen.push_back((double) -1.);
  else {
    const auto weight = std::get<1>(assoc.front());
    if (static_cast<double>(weight) < 0.7)
      m_trk_idx_gen.push_back((double) -1.);
    else {
      const auto mcp = std::get<0>(assoc.front());
      m_trk_idx_gen.push_back((double) addGen(mcp));
    }
  }
  return idx;
}

#ifdef WITH_ROOT
void SelCheckerTuple::accumulate(
  MCEvents const& mc_events,
  std::vector<Checker::Tracks> const& tracks,
  const VertexFit::TrackMVAVertex* svs,
  const bool* sel_results,
  const uint* sel_results_offsets,
  const uint* track_atomics,
  const uint* sv_atomics,
  const uint selected_events)
{

  for (size_t i_event = 0; i_event < mc_events.size(); ++i_event) {

    clear();

    const auto& mc_event = mc_events[i_event];
    const auto& mcps = mc_event.m_mcps;

    // Loop over MC particles
    for (auto mcp : mcps) {
      if (mcp.fromBeautyDecay || mcp.fromCharmDecay || mcp.fromStrangeDecay || mcp.DecayOriginMother_pid == 23) {
        addGen(mcp);
      }
    }

    if (i_event < selected_events) {
      m_event_pass_gec.push_back(1.);
      const auto& event_tracks = tracks[i_event];
      MCAssociator mcassoc {mcps};
      const uint* event_tracks_offsets = track_atomics + selected_events;
      const uint* sv_offsets = sv_atomics + selected_events;
      const uint event_n_svs = sv_atomics[i_event];
      const VertexFit::TrackMVAVertex* event_vertices = svs + sv_offsets[i_event];

      // Loop over tracks.
      for (size_t i_track = 0; i_track < event_tracks.size(); i_track++) {
        // First track.
        auto trackA = event_tracks[i_track];
        size_t idx1 = addTrack(trackA, mcassoc);
        if (idx1 == m_trk_p.size() -1) {
          for (uint i_line = Hlt1::startOneTrackLines; i_line < Hlt1::startTwoTrackLines; i_line++) {
            std::string line_name = Hlt1::Hlt1LineNames[i_line];
            const bool* decs = sel_results + sel_results_offsets[i_line] + event_tracks_offsets[i_event];
            m_trk_decisions[line_name].push_back(decs[i_track] ? 1. : 0.);
          }
        }
      }

      // Loop over SVs.
      for (size_t i_sv = 0; i_sv < event_n_svs; i_sv++) {
        if (event_vertices[i_sv].chi2 < 0) {
          continue;
        }
        auto trackA = event_tracks[(size_t)event_vertices[i_sv].trk1];
        auto trackB = event_tracks[(size_t)event_vertices[i_sv].trk2];
        size_t i_track = addTrack(trackA, mcassoc);
        size_t j_track = addTrack(trackB, mcassoc);
        addSV(event_vertices[i_sv], i_track, j_track);
        for (uint i_line = Hlt1::startTwoTrackLines; i_line < Hlt1::startThreeTrackLines; i_line++) {
          std::string line_name = Hlt1::Hlt1LineNames[i_line];
          const bool* decs = sel_results + sel_results_offsets[i_line] + sv_offsets[i_event];
          m_sv_decisions[line_name].push_back(decs[i_track] ? 1. : 0.);
        }
      }
    }
    else {
      m_event_pass_gec.push_back(0.);
    }

    m_tree->Fill();
  }
}
#else
void SelCheckerTuple::accumulate(
  MCEvents const&,
  std::vector<Checker::Tracks> const&,
  const VertexFit::TrackMVAVertex*,
  const bool*,
  const uint*,
  const uint*,
  const uint*,
  const uint)
{}
#endif

#ifdef WITH_ROOT
void SelCheckerTuple::report(size_t requested_events) const
{
  ;
  TArrayI nEvents(1);
  nEvents[0] = (int) requested_events;
  m_file->cd();
  m_file->WriteTObject(m_tree);
  m_file->WriteObject(&nEvents, "nEvents");
}
#else
void SelCheckerTuple::report(size_t) const {}
#endif
