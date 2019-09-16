#pragma once

#include <Common.h>
#include <CheckerTypes.h>
#include <CheckerInvoker.h>
#include <PV_Definitions.cuh>
#include <patPV_Definitions.cuh>
#include "MCAssociator.h"
#include "MCParticle.h"
#include "MCEvent.h"
#include "MCVertex.h"
#include "ParKalmanDefinitions.cuh"
#include "VertexDefinitions.cuh"

#include "ROOTHeaders.h"
#include <algorithm>

class SelCheckerTuple : public Checker::BaseChecker {

 public:
  struct SelTupleTag {
    static std::string const name;
  };
  using subdetector_t = SelTupleTag;

#ifdef WITH_ROOT
  std::string const m_directory;
#endif
  
  SelCheckerTuple(CheckerInvoker const* invoker, std::string const& root_file);

  virtual ~SelCheckerTuple() = default;

  void accumulate(
    MCEvents const& mc_events,
    std::vector<Checker::Tracks> const& tracks,
    const VertexFit::TrackMVAVertex* svs,
    const bool* one_track_decisions,
    const bool* two_track_decisions,
    const bool* single_muon_decisions,
    const bool* disp_dimuon_decisions,
    const bool* high_mass_dimuon_decisions,
    const int* track_atomics,
    const uint* sv_atomics,
    const uint selected_events);

  void report(size_t n_events) const override;
  
  int addGen(MCParticles::const_reference& mcp);
  int addPV(const RecPVInfo& pv);
  int addSV(const VertexFit::TrackMVAVertex& sv, const int idx1, const int idx2);
  int addTrack(Checker::Track& track, const MCAssociator& mcassoc);
  void clear();
  
 private:
#ifdef WITH_ROOT
  TTree* m_tree = nullptr;
  TFile* m_file = nullptr;
#endif

  // MC info.
  std::vector<float> m_gen_key;
  std::vector<float> m_gen_pid;
  std::vector<float> m_gen_p;
  std::vector<float> m_gen_pt;
  std::vector<float> m_gen_eta;
  std::vector<float> m_gen_phi;
  std::vector<float> m_gen_tau;
  std::vector<float> m_gen_ovtx_x;
  std::vector<float> m_gen_ovtx_y;
  std::vector<float> m_gen_ovtx_z;
  std::vector<float> m_gen_long;
  std::vector<float> m_gen_down;
  std::vector<float> m_gen_has_velo;
  std::vector<float> m_gen_has_ut;
  std::vector<float> m_gen_has_scifi;
  std::vector<float> m_gen_from_b;
  std::vector<float> m_gen_from_c;
  std::vector<float> m_gen_from_s;
  std::vector<float> m_gen_idx_mom;
  std::vector<float> m_gen_idx_decmom;
  std::vector<float> m_gen_mom_key;
  std::vector<float> m_gen_decmom_key;
  std::vector<float> m_gen_decmom_pid;
  std::vector<float> m_gen_decmom_tau;
  std::vector<float> m_gen_decmom_pt;
    
  // SV info.
  std::vector<float> m_sv_px;
  std::vector<float> m_sv_py;
  std::vector<float> m_sv_pz;
  std::vector<float> m_sv_x;
  std::vector<float> m_sv_y;
  std::vector<float> m_sv_z;
  std::vector<float> m_sv_cov00;
  std::vector<float> m_sv_cov10;
  std::vector<float> m_sv_cov11;
  std::vector<float> m_sv_cov20;
  std::vector<float> m_sv_cov21;
  std::vector<float> m_sv_cov22;
  std::vector<float> m_sv_sumpt;
  std::vector<float> m_sv_fdchi2;
  std::vector<float> m_sv_mdimu;
  std::vector<float> m_sv_mcor;
  std::vector<float> m_sv_eta;
  std::vector<float> m_sv_minipchi2;
  std::vector<float> m_sv_minpt;
  std::vector<float> m_sv_ntrksassoc;
  std::vector<float> m_sv_idx_trk1;
  std::vector<float> m_sv_idx_trk2;
  std::vector<float> m_sv_pass_two_track;
  std::vector<float> m_sv_pass_disp_dimuon;
  std::vector<float> m_sv_pass_high_mass_dimuon;
  
  // Track info.
  std::vector<float> m_trk_p;
  std::vector<float> m_trk_pt;
  std::vector<float> m_trk_eta;
  std::vector<float> m_trk_chi2;
  std::vector<float> m_trk_ndof;
  std::vector<float> m_trk_is_muon;
  std::vector<float> m_trk_kalman_ip;
  std::vector<float> m_trk_kalman_ipchi2;
  std::vector<float> m_trk_velo_ip;
  std::vector<float> m_trk_velo_ipchi2;
  std::vector<float> m_trk_idx_gen;
  std::vector<float> m_trk_pass_one_track;
  std::vector<float> m_trk_pass_single_muon;
  
};
