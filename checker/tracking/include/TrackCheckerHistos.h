/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

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
  std::map<std::string, std::unique_ptr<TH1D>> h_reconstructible_docaz;
  std::map<std::string, std::unique_ptr<TH2D>> h_reconstructible_eta_phi;
  std::map<std::string, std::unique_ptr<TH1D>> h_reconstructed_eta;
  std::map<std::string, std::unique_ptr<TH1D>> h_reconstructed_p;
  std::map<std::string, std::unique_ptr<TH1D>> h_reconstructed_pt;
  std::map<std::string, std::unique_ptr<TH1D>> h_reconstructed_phi;
  std::map<std::string, std::unique_ptr<TH1D>> h_reconstructed_nPV;
  std::map<std::string, std::unique_ptr<TH1D>> h_reconstructed_docaz;
  std::map<std::string, std::unique_ptr<TH2D>> h_reconstructed_eta_phi;

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
  std::unique_ptr<TH1D> h_matched_FromS_isMuon_Eta_reconstructed;
  std::unique_ptr<TH1D> h_matched_FromB_isMuon_Eta_reconstructed;
  std::unique_ptr<TH1D> h_not_matched_isMuon_Eta_reconstructed;
  std::unique_ptr<TH1D> h_muon_P_reconstructible;
  std::unique_ptr<TH1D> h_not_muon_P_reconstructible;
  std::unique_ptr<TH1D> h_matched_isMuon_P_reconstructed;
  std::unique_ptr<TH1D> h_matched_FromS_isMuon_P_reconstructed;
  std::unique_ptr<TH1D> h_matched_FromB_isMuon_P_reconstructed;
  std::unique_ptr<TH1D> h_not_matched_isMuon_P_reconstructed;
  std::unique_ptr<TH1D> h_muon_Pt_reconstructible;
  std::unique_ptr<TH1D> h_not_muon_Pt_reconstructible;
  std::unique_ptr<TH1D> h_matched_isMuon_Pt_reconstructed;
  std::unique_ptr<TH1D> h_matched_FromS_isMuon_Pt_reconstructed;
  std::unique_ptr<TH1D> h_matched_FromB_isMuon_Pt_reconstructed;
  std::unique_ptr<TH1D> h_not_matched_isMuon_Pt_reconstructed;
  std::unique_ptr<TH1D> h_muon_Phi_reconstructible;
  std::unique_ptr<TH1D> h_not_muon_Phi_reconstructible;
  std::unique_ptr<TH1D> h_matched_isMuon_Phi_reconstructed;
  std::unique_ptr<TH1D> h_matched_FromS_isMuon_Phi_reconstructed;
  std::unique_ptr<TH1D> h_matched_FromB_isMuon_Phi_reconstructed;
  std::unique_ptr<TH1D> h_not_matched_isMuon_Phi_reconstructed;
  std::unique_ptr<TH1D> h_muon_nPV_reconstructible;
  std::unique_ptr<TH1D> h_not_muon_nPV_reconstructible;
  std::unique_ptr<TH1D> h_matched_isMuon_nPV_reconstructed;
  std::unique_ptr<TH1D> h_matched_FromS_isMuon_nPV_reconstructed;
  std::unique_ptr<TH1D> h_matched_FromB_isMuon_nPV_reconstructed;
  std::unique_ptr<TH1D> h_not_matched_isMuon_nPV_reconstructed;

  std::unique_ptr<TH1D> h_ghost_isMuon_Eta_reconstructed;
  std::unique_ptr<TH1D> h_ghost_isMuon_nPV_reconstructed;

  TFile* m_file = nullptr;
  void write();
#endif

  std::string const m_directory;

  TrackCheckerHistos(
    CheckerInvoker const* invoker,
    std::string const& root_file,
    std::string const& directory,
    std::vector<Checker::HistoCategory> const& histo_categories);

  void fillReconstructibleHistos(const MCParticles& mcps, const Checker::HistoCategory& category);
  void fillReconstructedHistos(const MCParticle& mcp, Checker::HistoCategory& category);
  void fillTotalHistos(double nPV, double eta);
  void fillGhostHistos(double nPV, double eta);
  void fillMomentumResolutionHisto(const MCParticle& mcp, const float p, const float qop);
  void fillMuonIDHistos(const Checker::Track& track);
  void fillMuonIDMatchedHistos(const Checker::Track& track, const MCParticle& mcp);
  void fillMuonReconstructedMatchedIsMuon(const MCParticle& mcp);
  void fillMuonFromSReconstructedMatchedIsMuon(const MCParticle& mcp);
  void fillMuonFromBReconstructedMatchedIsMuon(const MCParticle& mcp);
  void fillMuonReconstructedNotMatchedIsMuon(const MCParticle& mcp);
  void fillMuonReconstructible(const MCParticle& mcp);
  void fillMuonGhostHistos(double nPV, double eta);
};
