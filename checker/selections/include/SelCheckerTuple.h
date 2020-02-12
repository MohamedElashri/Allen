#pragma once

#include <algorithm>

#include <Common.h>
#include <CudaCommon.h>
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
#include "LineTraverser.cuh"

class SelCheckerTuple : public Checker::BaseChecker {
  bool m_initialized_line_info = false;

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

#ifdef WITH_ROOT
  template<typename T>
  void clear_line_info()
  {
    const auto lambda_velo_ut_two_track_fn = [&](const unsigned long, const std::string& line_name) {
      m_mf_sv_decisions[line_name].clear();
    };
    Hlt1::TraverseLinesNames<T, Hlt1::VeloUTTwoTrackLine, decltype(lambda_velo_ut_two_track_fn)>::traverse(
      lambda_velo_ut_two_track_fn);

    const auto lambda_two_track_fn = [&](const unsigned long, const std::string& line_name) {
      m_sv_decisions[line_name].clear();
    };
    Hlt1::TraverseLinesNames<T, Hlt1::TwoTrackLine, decltype(lambda_two_track_fn)>::traverse(lambda_two_track_fn);

    const auto lambda_one_track_fn = [&](const unsigned long, const std::string& line_name) {
      m_trk_decisions[line_name].clear();
    };
    Hlt1::TraverseLinesNames<T, Hlt1::OneTrackLine, decltype(lambda_one_track_fn)>::traverse(lambda_one_track_fn);
  }

  void make_branch(
    const std::string& line_name,
    const std::string& prefix,
    std::map<std::string, std::vector<double>>& decisions);
  void fill();

  template<typename T>
  void accumulate(
    MCEvents const& mc_events,
    std::vector<Checker::Tracks> const& tracks,
    const VertexFit::TrackMVAVertex* svs,
    const bool* sel_results,
    const uint* sel_results_offsets,
    const uint* track_offsets,
    const uint* sv_offsets,
    const uint*,
    const uint selected_events)
  {
    if (!m_initialized_line_info) {
      m_initialized_line_info = true;

      const auto lambda_velo_ut_two_track_fn = [&](const unsigned long, const std::string& line_name) {
        make_branch(line_name, "mf_sv_pass_", m_mf_sv_decisions);
      };
      Hlt1::TraverseLinesNames<T, Hlt1::VeloUTTwoTrackLine, decltype(lambda_velo_ut_two_track_fn)>::traverse(
        lambda_velo_ut_two_track_fn);

      const auto lambda_two_track_fn = [&](const unsigned long, const std::string& line_name) {
        make_branch(line_name, "sv_pass_", m_sv_decisions);
      };
      Hlt1::TraverseLinesNames<T, Hlt1::TwoTrackLine, decltype(lambda_two_track_fn)>::traverse(lambda_two_track_fn);

      const auto lambda_one_track_fn = [&](const unsigned long, const std::string& line_name) {
        make_branch(line_name, "trk_pass_", m_trk_decisions);
      };
      Hlt1::TraverseLinesNames<T, Hlt1::OneTrackLine, decltype(lambda_one_track_fn)>::traverse(lambda_one_track_fn);
    }

    for (size_t i_event = 0; i_event < mc_events.size(); ++i_event) {

      clear();
      clear_line_info<T>();

      const auto& mc_event = mc_events[i_event];
      const auto& mcps = mc_event.m_mcps;

      // Loop over MC particles
      for (auto mcp : mcps) {
        if (mcp.fromBeautyDecay || mcp.fromCharmDecay || mcp.fromStrangeDecay || mcp.DecayOriginMother_pid == 23) {
          addGen(mcp);
        }
      }

      if (i_event >= selected_events) {
        m_event_pass_gec.push_back(0.);
        continue;
      }

      m_event_pass_gec.push_back(1.);
      const auto& event_tracks = tracks[i_event];
      MCAssociator mcassoc {mcps};
      const uint event_n_svs = sv_offsets[i_event + 1] - sv_offsets[i_event];
      const VertexFit::TrackMVAVertex* event_vertices = svs + sv_offsets[i_event];

      // Loop over tracks.
      for (size_t i_track = 0; i_track < event_tracks.size(); i_track++) {
        // First track.
        auto trackA = event_tracks[i_track];
        size_t idx1 = addTrack(trackA, mcassoc);
        if (idx1 == m_trk_p.size() - 1) {
          const auto lambda_one_track_fn = [&](const unsigned long i_line, const std::string& line_name) {
            const bool* decs = sel_results + sel_results_offsets[i_line] + track_offsets[i_event];
            m_trk_decisions[line_name].push_back(decs[i_track] ? 1. : 0.);
          };
          Hlt1::TraverseLinesNames<T, Hlt1::OneTrackLine, decltype(lambda_one_track_fn)>::traverse(lambda_one_track_fn);
        }
      }

      // Loop over SVs.
      for (size_t i_sv = 0; i_sv < event_n_svs; i_sv++) {
        if (event_vertices[i_sv].chi2 < 0) {
          continue;
        }
        auto trackA = event_tracks[(size_t) event_vertices[i_sv].trk1];
        auto trackB = event_tracks[(size_t) event_vertices[i_sv].trk2];
        size_t i_track = addTrack(trackA, mcassoc);
        size_t j_track = addTrack(trackB, mcassoc);
        addSV(event_vertices[i_sv], i_track, j_track);

        const auto lambda_two_track_fn = [&](const unsigned long i_line, const std::string& line_name) {
          const bool* decs = sel_results + sel_results_offsets[i_line] + sv_offsets[i_event];
          m_sv_decisions[line_name].push_back(decs[i_track] ? 1. : 0.);
        };
        Hlt1::TraverseLinesNames<T, Hlt1::TwoTrackLine, decltype(lambda_two_track_fn)>::traverse(lambda_two_track_fn);
      }
      // TODO: Loop over VeloUT SVs.
    }
    fill();
  }
#else
  template<typename T>
  void accumulate(
    MCEvents const&,
    std::vector<Checker::Tracks> const&,
    const VertexFit::TrackMVAVertex*,
    const bool*,
    const uint*,
    const uint*,
    const uint*,
    const uint*,
    const uint)
  {}
#endif

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
  std::vector<double> m_sv_ntrks16;
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

  // VeloUT SV info.
  std::map<std::string, std::vector<double>> m_mf_sv_decisions;
};
