#include <TrackCheckerHistos.h>

namespace {
  using Checker::HistoCategory;
} // namespace

TrackCheckerHistos::TrackCheckerHistos(
  CheckerInvoker const* invoker,
  std::string const& root_file,
  std::string const& directory,
  std::vector<HistoCategory> const& histo_categories) :
  m_directory {directory}
{
#ifdef WITH_ROOT
  m_file = invoker->root_file(root_file);
  auto* dir = static_cast<TDirectory*>(m_file->Get(m_directory.c_str()));
  if (!dir) {
    dir = m_file->mkdir(m_directory.c_str());
    dir = static_cast<TDirectory*>(m_file->Get(m_directory.c_str()));
  }
  dir->cd();

  // info_cout << m_file->GetName() << std::endl;
  // info_cout << dir->GetName() << std::endl;

  // histos for efficiency
  for (auto histoCat : histo_categories) {
    const std::string& category = histoCat.m_name;
    std::string name = category + "_Eta_reconstructible";
    if (category.find("eta25") != std::string::npos) {
      h_reconstructible_eta[name] = std::make_unique<TH1D>(name.c_str(), name.c_str(), 50, 0., 7.);
      name = category + "_Eta_reconstructed";
      h_reconstructed_eta[name] = std::make_unique<TH1D>(name.c_str(), name.c_str(), 50, 0., 7.);
      name = category + "_Eta_Phi_reconstructible";
      h_reconstructible_eta_phi[name] =
        std::make_unique<TH2D>(name.c_str(), name.c_str(), 50, 0., 7., 25, -3.142, 3.142);
      name = category + "_Eta_Phi_reconstructed";
      h_reconstructed_eta_phi[name] = std::make_unique<TH2D>(name.c_str(), name.c_str(), 50, 0., 7., 25, -3.142, 3.142);
    }
    else {
      h_reconstructible_eta[name] = std::make_unique<TH1D>(name.c_str(), name.c_str(), 100, -7., 7.);
      name = category + "_Eta_reconstructed";
      h_reconstructed_eta[name] = std::make_unique<TH1D>(name.c_str(), name.c_str(), 100, -7., 7.);
      name = category + "_Eta_Phi_reconstructible";
      h_reconstructible_eta_phi[name] =
        std::make_unique<TH2D>(name.c_str(), name.c_str(), 100, -7., 7., 25, -3.142, 3.142);
      name = category + "_Eta_Phi_reconstructed";
      h_reconstructed_eta_phi[name] =
        std::make_unique<TH2D>(name.c_str(), name.c_str(), 100, -7., 7., 25, -3.142, 3.142);
    }
    name = category + "_P_reconstructible";
    h_reconstructible_p[name] = std::make_unique<TH1D>(name.c_str(), name.c_str(), 50, 0., 100000.);
    name = category + "_Pt_reconstructible";
    h_reconstructible_pt[name] = std::make_unique<TH1D>(name.c_str(), name.c_str(), 30, 0., 5000.);
    name = category + "_Phi_reconstructible";
    h_reconstructible_phi[name] = std::make_unique<TH1D>(name.c_str(), name.c_str(), 25, -3.142, 3.142);
    name = category + "_nPV_reconstructible";
    h_reconstructible_nPV[name] = std::make_unique<TH1D>(name.c_str(), name.c_str(), 21, -0.5, 20.5);
    name = category + "_docaz_reconstructible";
    h_reconstructible_docaz[name] = std::make_unique<TH1D>(name.c_str(), name.c_str(), 30, 0., 3.);
    name = category + "_P_reconstructed";
    h_reconstructed_p[name] = std::make_unique<TH1D>(name.c_str(), name.c_str(), 50, 0., 100000.);
    name = category + "_Pt_reconstructed";
    h_reconstructed_pt[name] = std::make_unique<TH1D>(name.c_str(), name.c_str(), 30, 0., 5000.);
    name = category + "_Phi_reconstructed";
    h_reconstructed_phi[name] = std::make_unique<TH1D>(name.c_str(), name.c_str(), 25, -3.142, 3.142);
    name = category + "_nPV_reconstructed";
    h_reconstructed_nPV[name] = std::make_unique<TH1D>(name.c_str(), name.c_str(), 21, -0.5, 20.5);
    name = category + "_docaz_reconstructed";
    h_reconstructed_docaz[name] = std::make_unique<TH1D>(name.c_str(), name.c_str(), 30, 0., 3.);
  }

  // histos for ghost rate
  h_ghost_nPV = std::make_unique<TH1D>("nPV_Ghosts", "nPV_Ghosts", 21, -0.5, 20.5);
  h_total_nPV = std::make_unique<TH1D>("nPV_Total", "nPV_Total", 21, -0.5, 20.5);
  h_ghost_eta = std::make_unique<TH1D>("eta_Ghosts", "eta_Ghosts", 20, 0, 7);
  h_total_eta = std::make_unique<TH1D>("eta_Total", "eta_Total", 20, 0, 7);

  // histo for momentum resolution
  h_momentum_resolution =
    std::make_unique<TH2D>("momentum_resolution", "momentum resolution", 10, 0, 100000., 1000, -5., 5.);
  h_qop_resolution = std::make_unique<TH2D>("qop_resolution", "qop resolution", 10, -0.2e-3, 0.2e-3, 1000, -5., 5.);
  h_dqop_versus_qop =
    std::make_unique<TH2D>("dqop_vs_qop", "dqop vs. qop", 100, -0.2e-3, 0.2e-3, 100, -0.05e-3, 0.05e-3);
  h_dp_versus_p = std::make_unique<TH2D>("dp_vs_p", "dp vs. p", 100, 0, 100000., 1000, -10000., 10000.);
  h_momentum_matched = std::make_unique<TH1D>("p_matched", "p, matched", 100, 0, 100000.);

  // histo for muon ID
  h_muon_catboost_output_matched_muon =
    std::make_unique<TH1D>("muon_catboost_output_matched_muon", "muon_catboost_output_matched_muon", 200, -5., 5.);
  h_muon_catboost_output_matched_notMuon = std::make_unique<TH1D>(
    "muon_catboost_output_matched_notMuon", "muon_catboost_output_matched_notMuon", 200, -5., 5.);
  h_muon_catboost_output_matched_muon_ismuon_true = std::make_unique<TH1D>(
    "muon_catboost_output_matched_muon_ismuon_true", "muon_catboost_output_matched_muon_ismuon_true", 200, -5., 5.);
  h_muon_catboost_output_matched_notMuon_ismuon_true = std::make_unique<TH1D>(
    "muon_catboost_output_matched_notMuon_ismuon_true",
    "muon_catboost_output_matched_notMuon_ismuon_true",
    200,
    -5.,
    5.);
  h_muon_catboost_output_matched_muon_ismuon_false = std::make_unique<TH1D>(
    "muon_catboost_output_matched_muon_ismuon_false", "muon_catboost_output_matched_muon_ismuon_false", 200, -5., 5.);
  h_muon_catboost_output_matched_notMuon_ismuon_false = std::make_unique<TH1D>(
    "muon_catboost_output_matched_notMuon_ismuon_false",
    "muon_catboost_output_matched_notMuon_ismuon_false",
    200,
    -5.,
    5.);
  h_is_muon_matched_muon = std::make_unique<TH1D>("is_muon_matched_muon", "is_muon_matched_muon", 2, -0.5, 1.5);
  h_is_muon_matched_notMuon =
    std::make_unique<TH1D>("is_muon_matched_notMuon", "is_muon_catboost_matched_notMuon", 2, -0.5, 1.5);

  h_muon_Eta_reconstructible = std::make_unique<TH1D>("muon_Eta_reconstructible", "muon_Eta_reconstructible", 20, 0, 7);
  h_not_muon_Eta_reconstructible =
    std::make_unique<TH1D>("not_muon_Eta_reconstructible", "not_muon_Eta_reconstructible", 20, 0, 7);
  h_matched_isMuon_Eta_reconstructed =
    std::make_unique<TH1D>("matched_isMuon_Eta_reconstructed", "matched_isMuon_Eta_reconstructed", 20, 0, 7);
  h_matched_FromS_isMuon_Eta_reconstructed = std::make_unique<TH1D>(
    "matched_FromS_isMuon_Eta_reconstructed", "matched_FromS_isMuon_Eta_reconstructed", 20, 0, 7);
  h_matched_FromB_isMuon_Eta_reconstructed = std::make_unique<TH1D>(
    "matched_FromB_isMuon_Eta_reconstructed", "matched_FromB_isMuon_Eta_reconstructed", 20, 0, 7);
  h_not_matched_isMuon_Eta_reconstructed =
    std::make_unique<TH1D>("not_matched_isMuon_Eta_reconstructed", "not_matched_isMuon_Eta_reconstructed", 20, 0, 7);

  h_muon_P_reconstructible =
    std::make_unique<TH1D>("muon_P_reconstructible", "muon_P_reconstructible", 50, 0., 100000.);
  h_not_muon_P_reconstructible =
    std::make_unique<TH1D>("not_muon_P_reconstructible", "not_muon_P_reconstructible", 50, 0., 100000.);
  h_matched_isMuon_P_reconstructed =
    std::make_unique<TH1D>("matched_isMuon_P_reconstructed", "matched_isMuon_P_reconstructed", 50, 0., 100000.);
  h_matched_FromS_isMuon_P_reconstructed = std::make_unique<TH1D>(
    "matched_FromS_isMuon_P_reconstructed", "matched_FromS_isMuon_P_reconstructed", 50, 0., 100000.);
  h_matched_FromB_isMuon_P_reconstructed = std::make_unique<TH1D>(
    "matched_FromB_isMuon_P_reconstructed", "matched_FromB_isMuon_P_reconstructed", 50, 0., 100000.);
  h_not_matched_isMuon_P_reconstructed =
    std::make_unique<TH1D>("not_matched_isMuon_P_reconstructed", "not_matched_isMuon_P_reconstructed", 50, 0., 100000.);
  h_muon_Pt_reconstructible =
    std::make_unique<TH1D>("muon_Pt_reconstructible", "muon_Pt_reconstructible", 30, 0., 5000.);
  h_not_muon_Pt_reconstructible =
    std::make_unique<TH1D>("not_muon_Pt_reconstructible", "not_muon_Pt_reconstructible", 30, 0., 5000.);
  h_matched_isMuon_Pt_reconstructed =
    std::make_unique<TH1D>("matched_isMuon_Pt_reconstructed", "matched_isMuon_Pt_reconstructed", 30, 0., 5000.);
  h_matched_FromS_isMuon_Pt_reconstructed = std::make_unique<TH1D>(
    "matched_FromS_isMuon_Pt_reconstructed", "matched_FromS_isMuon_Pt_reconstructed", 30, 0., 5000.);
  h_matched_FromB_isMuon_Pt_reconstructed = std::make_unique<TH1D>(
    "matched_FromB_isMuon_Pt_reconstructed", "matched_FromB_isMuon_Pt_reconstructed", 30, 0., 5000.);
  h_not_matched_isMuon_Pt_reconstructed =
    std::make_unique<TH1D>("not_matched_isMuon_Pt_reconstructed", "not_matched_isMuon_Pt_reconstructed", 30, 0., 5000.);

  h_muon_Phi_reconstructible =
    std::make_unique<TH1D>("muon_Phi_reconstructible", "muon_Phi_reconstructible", 15, -3.142, 3.142);
  h_not_muon_Phi_reconstructible =
    std::make_unique<TH1D>("not_muon_Phi_reconstructible", "not_muon_Phi_reconstructible", 15, -3.142, 3.142);
  h_matched_isMuon_Phi_reconstructed =
    std::make_unique<TH1D>("matched_isMuon_Phi_reconstructed", "matched_isMuon_Phi_reconstructed", 15, -3.142, 3.142);
  h_matched_FromS_isMuon_Phi_reconstructed = std::make_unique<TH1D>(
    "matched_FromS_isMuon_Phi_reconstructed", "matched_FromS_isMuon_Phi_reconstructed", 15, -3.142, 3.142);
  h_matched_FromB_isMuon_Phi_reconstructed = std::make_unique<TH1D>(
    "matched_FromB_isMuon_Phi_reconstructed", "matched_FromB_isMuon_Phi_reconstructed", 15, -3.142, 3.142);
  h_not_matched_isMuon_Phi_reconstructed = std::make_unique<TH1D>(
    "not_matched_isMuon_Phi_reconstructed", "not_matched_isMuon_Phi_reconstructed", 15, -3.142, 3.142);

  h_muon_nPV_reconstructible =
    std::make_unique<TH1D>("muon_nPV_reconstructible", "muon_nPV_reconstructible", 21, -0.5, 20.5);
  h_not_muon_nPV_reconstructible =
    std::make_unique<TH1D>("not_muon_nPV_reconstructible", "not_muon_nPV_reconstructible", 21, -0.5, 20.5);
  h_matched_isMuon_nPV_reconstructed =
    std::make_unique<TH1D>("matched_isMuon_nPV_reconstructed", "matched_isMuon_nPV_reconstructed", 21, -0.5, 20.5);
  h_matched_FromS_isMuon_nPV_reconstructed = std::make_unique<TH1D>(
    "matched_FromS_isMuon_nPV_reconstructed", "matched_FromS_isMuon_nPV_reconstructed", 21, -0.5, 20.5);
  h_matched_FromB_isMuon_nPV_reconstructed = std::make_unique<TH1D>(
    "matched_FromB_isMuon_nPV_reconstructed", "matched_FromB_isMuon_nPV_reconstructed", 21, -0.5, 20.5);
  h_not_matched_isMuon_nPV_reconstructed = std::make_unique<TH1D>(
    "not_matched_isMuon_nPV_reconstructed", "not_matched_isMuon_nPV_reconstructed", 21, -0.5, 20.5);

  h_ghost_isMuon_Eta_reconstructed =
    std::make_unique<TH1D>("ghost_isMuon_Eta_reconstructed", "ghost_isMuon_Eta_reconstructed", 20, 0, 7);
  h_ghost_isMuon_nPV_reconstructed =
    std::make_unique<TH1D>("ghost_isMuon_nPV_reconstructed", "ghost_isMuon_nPV_reconstructed", 21, -0.5, 20.5);
#else
  _unused(invoker);
  _unused(root_file);
  _unused(directory);
  _unused(histo_categories);
#endif
}

#ifdef WITH_ROOT
void TrackCheckerHistos::write()
{
  auto* dir = static_cast<TDirectory*>(m_file->Get(m_directory.c_str()));
  if (!dir) {
    dir = m_file->mkdir(m_directory.c_str());
    dir = static_cast<TDirectory*>(m_file->Get(m_directory.c_str()));
  }
  std::tuple histograms {std::ref(h_dp_versus_p),
                         std::ref(h_momentum_resolution),
                         std::ref(h_qop_resolution),
                         std::ref(h_dqop_versus_qop),
                         std::ref(h_momentum_matched),
                         std::ref(h_ghost_nPV),
                         std::ref(h_total_nPV),
                         std::ref(h_ghost_eta),
                         std::ref(h_total_eta),
                         std::ref(h_muon_catboost_output_matched_muon),
                         std::ref(h_muon_catboost_output_matched_notMuon),
                         std::ref(h_muon_catboost_output_matched_muon_ismuon_true),
                         std::ref(h_muon_catboost_output_matched_notMuon_ismuon_true),
                         std::ref(h_muon_catboost_output_matched_muon_ismuon_false),
                         std::ref(h_muon_catboost_output_matched_notMuon_ismuon_false),
                         std::ref(h_is_muon_matched_muon),
                         std::ref(h_is_muon_matched_notMuon),
                         std::ref(h_muon_Eta_reconstructible),
                         std::ref(h_not_muon_Eta_reconstructible),
                         std::ref(h_matched_isMuon_Eta_reconstructed),
                         std::ref(h_matched_FromS_isMuon_Eta_reconstructed),
                         std::ref(h_matched_FromB_isMuon_Eta_reconstructed),
                         std::ref(h_not_matched_isMuon_Eta_reconstructed),
                         std::ref(h_muon_P_reconstructible),
                         std::ref(h_not_muon_P_reconstructible),
                         std::ref(h_matched_isMuon_P_reconstructed),
                         std::ref(h_matched_FromS_isMuon_P_reconstructed),
                         std::ref(h_matched_FromB_isMuon_P_reconstructed),
                         std::ref(h_not_matched_isMuon_P_reconstructed),
                         std::ref(h_muon_Pt_reconstructible),
                         std::ref(h_not_muon_Pt_reconstructible),
                         std::ref(h_matched_isMuon_Pt_reconstructed),
                         std::ref(h_matched_FromS_isMuon_Pt_reconstructed),
                         std::ref(h_matched_FromB_isMuon_Pt_reconstructed),
                         std::ref(h_not_matched_isMuon_Pt_reconstructed),
                         std::ref(h_muon_Phi_reconstructible),
                         std::ref(h_not_muon_Phi_reconstructible),
                         std::ref(h_matched_isMuon_Phi_reconstructed),
                         std::ref(h_matched_FromS_isMuon_Phi_reconstructed),
                         std::ref(h_matched_FromB_isMuon_Phi_reconstructed),
                         std::ref(h_not_matched_isMuon_Phi_reconstructed),
                         std::ref(h_muon_nPV_reconstructible),
                         std::ref(h_not_muon_nPV_reconstructible),
                         std::ref(h_matched_isMuon_nPV_reconstructed),
                         std::ref(h_matched_FromS_isMuon_nPV_reconstructed),
                         std::ref(h_matched_FromB_isMuon_nPV_reconstructed),
                         std::ref(h_not_matched_isMuon_nPV_reconstructed),
                         std::ref(h_ghost_isMuon_nPV_reconstructed),
                         std::ref(h_ghost_isMuon_Eta_reconstructed)};
  for_each(histograms, [dir](auto& histo) {
    histo.get()->SetDirectory(nullptr);
    dir->WriteTObject(histo.get().get());
  });

  std::tuple histo_maps {std::ref(h_reconstructible_eta),
                         std::ref(h_reconstructible_p),
                         std::ref(h_reconstructible_pt),
                         std::ref(h_reconstructible_phi),
                         std::ref(h_reconstructible_nPV),
                         std::ref(h_reconstructible_docaz),
                         std::ref(h_reconstructed_eta),
                         std::ref(h_reconstructed_p),
                         std::ref(h_reconstructed_pt),
                         std::ref(h_reconstructed_phi),
                         std::ref(h_reconstructed_nPV),
                         std::ref(h_reconstructible_eta_phi),
                         std::ref(h_reconstructed_eta_phi),
                         std::ref(h_reconstructed_docaz)};
  for_each(histo_maps, [dir](auto& histo_map) {
    for (auto const& entry : histo_map.get()) {
      entry.second->SetDirectory(nullptr);
      dir->WriteTObject(entry.second.get());
    }
  });
}
#endif

void TrackCheckerHistos::fillReconstructibleHistos(const MCParticles& mcps, const HistoCategory& category)
{
#ifdef WITH_ROOT
  const std::string eta_name = category.m_name + "_Eta_reconstructible";
  const std::string p_name = category.m_name + "_P_reconstructible";
  const std::string pt_name = category.m_name + "_Pt_reconstructible";
  const std::string phi_name = category.m_name + "_Phi_reconstructible";
  const std::string nPV_name = category.m_name + "_nPV_reconstructible";
  const std::string eta_phi_name = category.m_name + "_Eta_Phi_reconstructible";
  const std::string docaz_name = category.m_name + "_docaz_reconstructible";
  for (auto mcp : mcps) {
    if (category.m_accept(mcp)) {
      h_reconstructible_eta[eta_name]->Fill(mcp.eta);
      h_reconstructible_p[p_name]->Fill(mcp.p);
      h_reconstructible_pt[pt_name]->Fill(mcp.pt);
      h_reconstructible_phi[phi_name]->Fill(mcp.phi);
      h_reconstructible_nPV[nPV_name]->Fill(mcp.nPV);
      h_reconstructible_eta_phi[eta_phi_name]->Fill(mcp.eta, mcp.phi);
      float tx = std::sin(mcp.phi) / std::sinh(mcp.eta);
      float ty = std::cos(mcp.phi) / std::sinh(mcp.eta);
      float docaz = std::abs(ty * mcp.ovtx_x - tx * mcp.ovtx_y) / std::sqrt(tx * tx + ty * ty);
      h_reconstructible_docaz[docaz_name]->Fill(docaz);
    }
  }
#else
  _unused(mcps);
  _unused(category);
#endif
}

void TrackCheckerHistos::fillReconstructedHistos(const MCParticle& mcp, HistoCategory& category)
{
#ifdef WITH_ROOT
  if (!(category.m_accept(mcp))) return;
  const std::string eta_name = category.m_name + "_Eta_reconstructed";
  const std::string p_name = category.m_name + "_P_reconstructed";
  const std::string pt_name = category.m_name + "_Pt_reconstructed";
  const std::string phi_name = category.m_name + "_Phi_reconstructed";
  const std::string nPV_name = category.m_name + "_nPV_reconstructed";
  const std::string eta_phi_name = category.m_name + "_Eta_Phi_reconstructed";
  const std::string docaz_name = category.m_name + "_docaz_reconstructed";
  h_reconstructed_eta[eta_name]->Fill(mcp.eta);
  h_reconstructed_p[p_name]->Fill(mcp.p);
  h_reconstructed_pt[pt_name]->Fill(mcp.pt);
  h_reconstructed_phi[phi_name]->Fill(mcp.phi);
  h_reconstructed_nPV[nPV_name]->Fill(mcp.nPV);
  h_reconstructed_eta_phi[eta_phi_name]->Fill(mcp.eta, mcp.phi);
  float tx = std::sin(mcp.phi) / std::sinh(mcp.eta);
  float ty = std::cos(mcp.phi) / std::sinh(mcp.eta);
  float docaz = std::abs(ty * mcp.ovtx_x - tx * mcp.ovtx_y) / std::sqrt(tx * tx + ty * ty);
  h_reconstructed_docaz[docaz_name]->Fill(docaz);
#else
  _unused(mcp);
  _unused(category);
#endif
}

void TrackCheckerHistos::fillTotalHistos(double nPV, double eta)
{
#ifdef WITH_ROOT
  h_total_nPV->Fill(nPV);
  h_total_eta->Fill(eta);
#else
  _unused(nPV);
  _unused(eta);
#endif
}

void TrackCheckerHistos::fillGhostHistos(double nPV, double eta)
{
#ifdef WITH_ROOT
  h_ghost_nPV->Fill(nPV);
  h_ghost_eta->Fill(eta);
#else
  _unused(nPV);
  _unused(eta);
#endif
}

void TrackCheckerHistos::fillMomentumResolutionHisto(const MCParticle& mcp, const float p, const float qop)
{
#ifdef WITH_ROOT
  float mc_qop = mcp.charge / mcp.p;
  h_dp_versus_p->Fill(mcp.p, (mcp.p - p));
  h_momentum_resolution->Fill(mcp.p, (mcp.p - p) / mcp.p);
  h_qop_resolution->Fill(mc_qop, (mc_qop - qop) / mc_qop);
  h_dqop_versus_qop->Fill(mc_qop, mc_qop - qop);
  h_momentum_matched->Fill(mcp.p);
#else
  _unused(mcp);
  _unused(p);
  _unused(qop);
#endif
}

void TrackCheckerHistos::fillMuonReconstructedMatchedIsMuon(const MCParticle& mcp)
{
#ifdef WITH_ROOT
  h_matched_isMuon_Eta_reconstructed->Fill(mcp.eta);
  h_matched_isMuon_P_reconstructed->Fill(mcp.p);
  h_matched_isMuon_Pt_reconstructed->Fill(mcp.pt);
  h_matched_isMuon_Phi_reconstructed->Fill(mcp.phi);
  h_matched_isMuon_nPV_reconstructed->Fill(mcp.nPV);
#else
  _unused(mcp);
#endif
}

void TrackCheckerHistos::fillMuonFromSReconstructedMatchedIsMuon(const MCParticle& mcp)
{
#ifdef WITH_ROOT
  h_matched_FromS_isMuon_Eta_reconstructed->Fill(mcp.eta);
  h_matched_FromS_isMuon_P_reconstructed->Fill(mcp.p);
  h_matched_FromS_isMuon_Pt_reconstructed->Fill(mcp.pt);
  h_matched_FromS_isMuon_Phi_reconstructed->Fill(mcp.phi);
  h_matched_FromS_isMuon_nPV_reconstructed->Fill(mcp.nPV);
#else
  _unused(mcp);
#endif
}

void TrackCheckerHistos::fillMuonFromBReconstructedMatchedIsMuon(const MCParticle& mcp)
{
#ifdef WITH_ROOT
  h_matched_FromB_isMuon_Eta_reconstructed->Fill(mcp.eta);
  h_matched_FromB_isMuon_P_reconstructed->Fill(mcp.p);
  h_matched_FromB_isMuon_Pt_reconstructed->Fill(mcp.pt);
  h_matched_FromB_isMuon_Phi_reconstructed->Fill(mcp.phi);
  h_matched_FromB_isMuon_nPV_reconstructed->Fill(mcp.nPV);
#else
  _unused(mcp);
#endif
}

void TrackCheckerHistos::fillMuonReconstructedNotMatchedIsMuon(const MCParticle& mcp)
{
#ifdef WITH_ROOT
  h_not_matched_isMuon_Eta_reconstructed->Fill(mcp.eta);
  h_not_matched_isMuon_P_reconstructed->Fill(mcp.p);
  h_not_matched_isMuon_Pt_reconstructed->Fill(mcp.pt);
  h_not_matched_isMuon_Phi_reconstructed->Fill(mcp.phi);
  h_not_matched_isMuon_nPV_reconstructed->Fill(mcp.nPV);
#else
  _unused(mcp);
#endif
}

void TrackCheckerHistos::fillMuonReconstructible(const MCParticle& mcp)
{
#ifdef WITH_ROOT
  if (std::abs(mcp.pid) == 13) {
    h_muon_Eta_reconstructible->Fill(mcp.eta);
    h_muon_P_reconstructible->Fill(mcp.p);
    h_muon_Pt_reconstructible->Fill(mcp.pt);
    h_muon_Phi_reconstructible->Fill(mcp.phi);
    h_muon_nPV_reconstructible->Fill(mcp.nPV);
  }
  else {
    h_not_muon_Eta_reconstructible->Fill(mcp.eta);
    h_not_muon_P_reconstructible->Fill(mcp.p);
    h_not_muon_Pt_reconstructible->Fill(mcp.pt);
    h_not_muon_Phi_reconstructible->Fill(mcp.phi);
    h_not_muon_nPV_reconstructible->Fill(mcp.nPV);
  }
#else
  _unused(mcp);
#endif
}

void TrackCheckerHistos::fillMuonGhostHistos(double nPV, double eta)
{
#ifdef WITH_ROOT
  h_ghost_isMuon_nPV_reconstructed->Fill(nPV);
  h_ghost_isMuon_Eta_reconstructed->Fill(eta);
#else
  _unused(nPV);
  _unused(eta);
#endif
}

void TrackCheckerHistos::fillMuonIDMatchedHistos(const Checker::Track& track, const MCParticle& mcp)
{
#ifdef WITH_ROOT
  if (std::abs(mcp.pid) == 13) {
    h_muon_catboost_output_matched_muon->Fill(track.muon_catboost_output);
    h_is_muon_matched_muon->Fill(track.is_muon);
    if (track.is_muon == true) {
      h_muon_catboost_output_matched_muon_ismuon_true->Fill(track.muon_catboost_output);
    }
    else {
      h_muon_catboost_output_matched_muon_ismuon_false->Fill(track.muon_catboost_output);
    }
  }
  else {
    h_muon_catboost_output_matched_notMuon->Fill(track.muon_catboost_output);
    h_is_muon_matched_notMuon->Fill(track.is_muon);
    if (track.is_muon == true) {
      h_muon_catboost_output_matched_notMuon_ismuon_true->Fill(track.muon_catboost_output);
    }
    else {
      h_muon_catboost_output_matched_notMuon_ismuon_false->Fill(track.muon_catboost_output);
    }
  }
#else
  _unused(track);
  _unused(mcp);
#endif
}
