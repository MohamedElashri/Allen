/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
/** @file TrackChecker.h
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
 */

#pragma once

#include <functional>
#include <set>
#include <unordered_map>
#include <string>
#include <vector>
#include "Logger.h"
#include "MCAssociator.h"
#include "CheckerTypes.h"
#include "CheckerInvoker.h"
#include "MCEvent.h"

#include "ROOTHeaders.h"

float eta_from_rho(const float rho);

struct TrackCheckerHistos;

class TrackChecker : public Checker::BaseChecker {
protected:
  bool m_print = false;

  std::vector<Checker::TrackEffReport> m_categories;
  std::vector<Checker::HistoCategory> m_histo_categories;
  std::string m_trackerName = "";

  const float m_minweight = 0.7f;
  std::size_t m_nevents = 0;
  std::size_t m_ntracks = 0;
  std::size_t m_nghosts = 0;
  float m_ghostperevent = 0.f;
  float m_ghosttriggerperevent = 0.f;
  std::size_t m_ntrackstrigger = 0;
  std::size_t m_nghoststrigger = 0;

  std::size_t m_n_tracks_matched_to_MCP = 0;
  std::size_t m_n_MCPs_muon = 0;
  std::size_t m_n_MCPs_not_muon = 0;

  std::size_t n_is_muon_true = 0;
  std::size_t n_is_muon_true_fromS = 0;
  std::size_t n_is_muon_true_fromB = 0;
  std::size_t n_is_muon_misID = 0;
  std::size_t n_matched_muons = 0;
  std::size_t n_matched_muons_fromS = 0;
  std::size_t n_matched_muons_fromB = 0;
  std::size_t n_matched_not_muons = 0;
  std::size_t n_is_muon_ghost = 0;

public:
  TrackChecker(
    std::string name,
    std::vector<Checker::TrackEffReport> categories,
    std::vector<Checker::HistoCategory> histo_categories,
    CheckerInvoker const* invoker,
    std::string const& root_file,
    std::string const& directory,
    bool print = false);

  // FIXME: required until nvcc supports C++17 and m_histos
  virtual ~TrackChecker();

  std::string const& name() { return m_trackerName; }

  void report(size_t n_events) const override;

  template<typename T>
  void accumulate(const MCEvents& mc_events, const std::vector<Checker::Tracks>& tracks)
  {
    for (size_t evnum = 0; evnum < tracks.size(); ++evnum) {
      const auto& mc_event = mc_events[evnum];
      const auto& event_tracks = tracks[evnum];

      (*this)(event_tracks, mc_event, get_num_hits_subdetector<typename T::subdetector_t>);

      // Check all tracks for duplicate LHCb IDs
      for (size_t i_track = 0; i_track < event_tracks.size(); ++i_track) {
        const auto& track = event_tracks[i_track];
        auto ids = track.ids();
        std::sort(std::begin(ids), std::end(ids));
        bool containsDuplicates = (std::unique(std::begin(ids), std::end(ids))) != std::end(ids);
        if (containsDuplicates) {
          warning_cout << "WARNING: Track #" << i_track << " contains duplicate LHCb IDs" << std::endl << std::hex;
          for (auto id : ids) {
            warning_cout << "0x" << id << ", ";
          }
          warning_cout << std::endl << std::endl << std::dec;
        }
      }
    }
  }

  void operator()(
    const Checker::Tracks& tracks,
    const MCEvent& mc_event,
    const std::function<uint32_t(const MCParticle&)>& get_num_hits_subdetector);

  const std::vector<Checker::HistoCategory>& histo_categories() const { return m_histo_categories; }

  std::tuple<bool, MCParticles::const_iterator> match_track_to_MCPs(
    const MCAssociator& mc_assoc,
    const Checker::Tracks& tracks,
    const int i_track,
    std::unordered_map<uint32_t, std::vector<MCAssociator::TrackWithWeight>>& assoc_table);

  void muon_id_matching(
    const std::vector<MCAssociator::TrackWithWeight> tracks_with_weight,
    MCParticles::const_reference& mcp,
    const Checker::Tracks& tracks);

  // FIXME: Can't use unique_ptr here because we need a forward
  // declaration of TrackCheckerHistos to allow C++17 in host-only
  // code and C++14 in device code. Will fix once nvcc supports C++17
  TrackCheckerHistos* m_histos = nullptr;
};

struct TrackCheckerVelo : public TrackChecker {
  using subdetector_t = Checker::Subdetector::Velo;
  TrackCheckerVelo(CheckerInvoker const* invoker, std::string const& root_file);
};

struct TrackCheckerVeloUT : public TrackChecker {
  using subdetector_t = Checker::Subdetector::UT;
  TrackCheckerVeloUT(CheckerInvoker const* invoker, std::string const& root_file);
};

struct TrackCheckerForward : public TrackChecker {
  using subdetector_t = Checker::Subdetector::SciFi;
  TrackCheckerForward(CheckerInvoker const* invoker, std::string const& root_file);
};
