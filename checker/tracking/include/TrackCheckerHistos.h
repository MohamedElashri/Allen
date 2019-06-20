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
  std::unique_ptr<TH1D> h_ghost_eta;
  std::unique_ptr<TH1D> h_total_eta;  
  std::unique_ptr<TH2D> h_dp_versus_p;
  std::unique_ptr<TH2D> h_momentum_resolution;
  std::unique_ptr<TH2D> h_qop_resolution;
  std::unique_ptr<TH2D> h_dqop_versus_qop;
  std::unique_ptr<TH1D> h_momentum_matched;

  std::unique_ptr<TH1D> h_muon_catboost_output_matched_muon;
  std::unique_ptr<TH1D> h_muon_catboost_output_matched_notMuon;
  std::unique_ptr<TH1D> h_muon_catboost_output_matched_muon_ismuon_true;
  std::unique_ptr<TH1D> h_muon_catboost_output_matched_notMuon_ismuon_true; 
  std::unique_ptr<TH1D> h_muon_catboost_output_matched_muon_ismuon_false;
  std::unique_ptr<TH1D> h_muon_catboost_output_matched_notMuon_ismuon_false; 
  std::unique_ptr<TH1D> h_is_muon_matched_muon;
  std::unique_ptr<TH1D> h_is_muon_matched_notMuon;
  
  std::unique_ptr<TH1D> h_muon_Eta_reconstructible;
  std::unique_ptr<TH1D> h_not_muon_Eta_reconstructible;
  std::unique_ptr<TH1D> h_matched_isMuon_Eta_reconstructed;
  std::unique_ptr<TH1D> h_not_matched_isMuon_Eta_reconstructed; 
  std::unique_ptr<TH1D> h_muon_P_reconstructible;
  std::unique_ptr<TH1D> h_not_muon_P_reconstructible;
  std::unique_ptr<TH1D> h_matched_isMuon_P_reconstructed;
  std::unique_ptr<TH1D> h_not_matched_isMuon_P_reconstructed; 
  std::unique_ptr<TH1D> h_muon_Pt_reconstructible;
  std::unique_ptr<TH1D> h_not_muon_Pt_reconstructible;
  std::unique_ptr<TH1D> h_matched_isMuon_Pt_reconstructed;
  std::unique_ptr<TH1D> h_not_matched_isMuon_Pt_reconstructed; 
  std::unique_ptr<TH1D> h_muon_Phi_reconstructible;
  std::unique_ptr<TH1D> h_not_muon_Phi_reconstructible;
  std::unique_ptr<TH1D> h_matched_isMuon_Phi_reconstructed;
  std::unique_ptr<TH1D> h_not_matched_isMuon_Phi_reconstructed; 
  std::unique_ptr<TH1D> h_muon_nPV_reconstructible;
  std::unique_ptr<TH1D> h_not_muon_nPV_reconstructible;
  std::unique_ptr<TH1D> h_matched_isMuon_nPV_reconstructed;
  std::unique_ptr<TH1D> h_not_matched_isMuon_nPV_reconstructed; 

  std::unique_ptr<TH1D> h_ghost_isMuon_Eta_reconstructed;
  std::unique_ptr<TH1D> h_ghost_isMuon_nPV_reconstructed;
  
  void write(TDirectory* f);
#endif

  TrackCheckerHistos(const std::vector<Checker::HistoCategory>& histo_categories);

  void fillReconstructibleHistos(const MCParticles& mcps, const Checker::HistoCategory& category);
  void fillReconstructedHistos(const MCParticle& mcp, Checker::HistoCategory& category);
  void fillTotalHistos(const MCParticle& mcp, const Checker::Track& track);
  void fillGhostHistos(const MCParticle& mcp, const Checker::Track& track);
  void fillMomentumResolutionHisto(const MCParticle& mcp, const float p, const float qop);
  void fillMuonIDHistos(const Checker::Track& track);
  void fillMuonIDMatchedHistos(const Checker::Track& track, const MCParticle& mcp);
  void fillMuonReconstructedMatchedIsMuon(const MCParticle& mcp);
  void fillMuonReconstructedNotMatchedIsMuon(const MCParticle& mcp);
  void fillMuonReconstructible(const MCParticle& mcp); 
  void fillMuonGhostHistos(const MCParticle& mcp, const Checker::Track& track); 
};
