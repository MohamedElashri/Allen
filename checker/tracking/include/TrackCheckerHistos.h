#include <memory>
#include "TrackChecker.h"
#include "ROOTHeaders.h"

struct TrackCheckerHistos {
#ifdef WITH_ROOT
  std::map<std::string, std::unique_ptr<TH1D>> h_reconstructible_eta;
  std::map<std::string, std::unique_ptr<TH1D>> h_reconstructible_p;
  std::map<std::string, std::unique_ptr<TH1D>> h_reconstructible_pt;
  std::map<std::string, std::unique_ptr<TH1D>> h_reconstructible_phi;
  std::map<std::string, std::unique_ptr<TH1D>> h_reconstructible_nPV;
  std::map<std::string, std::unique_ptr<TH1D>> h_reconstructed_eta;
  std::map<std::string, std::unique_ptr<TH1D>> h_reconstructed_p;
  std::map<std::string, std::unique_ptr<TH1D>> h_reconstructed_pt;
  std::map<std::string, std::unique_ptr<TH1D>> h_reconstructed_phi;
  std::map<std::string, std::unique_ptr<TH1D>> h_reconstructed_nPV;

  std::unique_ptr<TH1D> h_ghost_nPV;
  std::unique_ptr<TH1D> h_total_nPV;
  std::unique_ptr<TH2D> h_dp_versus_p;
  std::unique_ptr<TH2D> h_momentum_resolution;
  std::unique_ptr<TH2D> h_qop_resolution;
  std::unique_ptr<TH2D> h_dqop_versus_qop;
  std::unique_ptr<TH1D> h_momentum_matched;
  std::unique_ptr<TH1D> h_muon_catboost_output_matched_muon;
  std::unique_ptr<TH1D> h_muon_catboost_output_matched_notMuon;
  std::unique_ptr<TH1D> h_muon_catboost_output_matched_muon_ismuon_true;
  std::unique_ptr<TH1D> h_muon_catboost_output_matched_notMuon_ismuon_true;
  std::unique_ptr<TH1D> h_is_muon_matched_muon;
  std::unique_ptr<TH1D> h_is_muon_matched_notMuon;

  void write(TDirectory* f);
#endif

  TrackCheckerHistos(const std::vector<Checker::HistoCategory>& histo_categories);

  void fillReconstructibleHistos(const MCParticles& mcps, const Checker::HistoCategory& category);
  void fillReconstructedHistos(const MCParticle& mcp, Checker::HistoCategory& category);
  void fillTotalHistos(const MCParticle& mcp);
  void fillGhostHistos(const MCParticle& mcp);
  void fillMomentumResolutionHisto(const MCParticle& mcp, const float p, const float qop);
  void fillMuonIDHistos(const Checker::Track& track);
  void fillMuonIDMatchedHistos(const Checker::Track& track, const MCParticle& mcp);

};
