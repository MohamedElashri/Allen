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
#include "RawBanksDefinitions.cuh"
#include "LineInfo.cuh"

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
    const bool* sel_results,
    const uint* sel_results_atomics,
    const int* track_atomics,
    const uint* sv_atomics,
    const uint selected_events);

  void report(size_t n_events) const override;

  size_t addGen(MCParticles::const_reference& mcp);
  size_t addPV(const RecPVInfo& pv);
  size_t addSV(const VertexFit::TrackMVAVertex& sv, const int idx1, const int idx2);
  size_t addTrack(Checker::Track& track, const MCAssociator& mcassoc);
  void clear();

private:
#ifdef WITH_ROOT
  TTree* m_tree = nullptr;
  TFile* m_file = nullptr;
#endif

  // Event info.
  std::vector<double> m_event_pass_gec;

  // MC info.
  std::vector<double> m_gen_key;
  std::vector<double> m_gen_pid;
  std::vector<double> m_gen_p;
  std::vector<double> m_gen_pt;
  std::vector<double> m_gen_eta;
  std::vector<double> m_gen_phi;
  std::vector<double> m_gen_tau;
  std::vector<double> m_gen_ovtx_x;
  std::vector<double> m_gen_ovtx_y;
  std::vector<double> m_gen_ovtx_z;
  std::vector<double> m_gen_long;
  std::vector<double> m_gen_down;
  std::vector<double> m_gen_has_velo;
  std::vector<double> m_gen_has_ut;
  std::vector<double> m_gen_has_scifi;
  std::vector<double> m_gen_from_b;
  std::vector<double> m_gen_from_c;
  std::vector<double> m_gen_from_s;
  std::vector<double> m_gen_idx_mom;
  std::vector<double> m_gen_idx_decmom;
  std::vector<double> m_gen_mom_key;
  std::vector<double> m_gen_decmom_key;
  std::vector<double> m_gen_decmom_pid;
  std::vector<double> m_gen_decmom_tau;
  std::vector<double> m_gen_decmom_pt;

  // SV info.
  std::vector<double> m_sv_px;
  std::vector<double> m_sv_py;
  std::vector<double> m_sv_pz;
  std::vector<double> m_sv_x;
  std::vector<double> m_sv_y;
  std::vector<double> m_sv_z;
  std::vector<double> m_sv_cov00;
  std::vector<double> m_sv_cov10;
  std::vector<double> m_sv_cov11;
  std::vector<double> m_sv_cov20;
  std::vector<double> m_sv_cov21;
  std::vector<double> m_sv_cov22;
  std::vector<double> m_sv_sumpt;
  std::vector<double> m_sv_fdchi2;
  std::vector<double> m_sv_mdimu;
  std::vector<double> m_sv_mcor;
  std::vector<double> m_sv_eta;
  std::vector<double> m_sv_minipchi2;
  std::vector<double> m_sv_minpt;
  std::vector<double> m_sv_ntrksassoc;
  std::vector<double> m_sv_idx_trk1;
  std::vector<double> m_sv_idx_trk2;
  std::map<std::string, std::vector<double>> m_sv_decisions;

  // Track info.
  std::vector<double> m_trk_p;
  std::vector<double> m_trk_pt;
  std::vector<double> m_trk_eta;
  std::vector<double> m_trk_chi2;
  std::vector<double> m_trk_ndof;
  std::vector<double> m_trk_is_muon;
  std::vector<double> m_trk_kalman_ip;
  std::vector<double> m_trk_kalman_ipchi2;
  std::vector<double> m_trk_velo_ip;
  std::vector<double> m_trk_velo_ipchi2;
  std::vector<double> m_trk_idx_gen;
  std::map<std::string, std::vector<double>> m_trk_decisions;
};
