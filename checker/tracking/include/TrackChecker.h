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
#include "TrackCheckerHistos.h"

float eta_from_rho(const float rho);

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
    bool print = false);

  // FIXME: required until nvcc supports C++17 and m_histos
  virtual ~TrackChecker();

  std::string const& name() { return m_trackerName; }

  void report(size_t n_events) const override;

  template<typename T>
  void accumulate(
    const MCEvents& mc_events,
    const std::vector<Checker::Tracks>& tracks,
    const std::vector<unsigned>& event_list)
  {
    for (size_t i = 0; i < event_list.size(); ++i) {
      const auto evnum = event_list[i];
      const auto& event_tracks = tracks[i];
      const auto& mc_event = mc_events[evnum];

      accumulate_impl<T>(event_tracks, mc_event);

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

  template<typename T>
  std::tuple<bool, MCParticles::const_iterator> match_track_to_MCPs(
    const MCAssociator& mc_assoc,
    const Checker::Tracks& tracks,
    const int i_track,
    std::unordered_map<uint32_t, std::vector<MCAssociator::TrackWithWeight>>& assoc_table)
  {
    const auto& track = tracks[i_track];

    // Note: This code is based heavily on
    //       https://gitlab.cern.ch/lhcb/Rec/blob/master/Pr/PrMCTools/src/PrTrackAssociator.cpp
    //
    // check LHCbIDs for MC association
    Checker::TruthCounter total_counter;
    std::unordered_map<unsigned, Checker::TruthCounter> truth_counters;
    int n_meas = 0;

    const auto& ids = track.ids();
    for (const auto& id : ids) {
      if (lhcb_id::is_velo(id)) {
        n_meas++;
        total_counter.n_velo++;
        const auto it_vec = mc_assoc.find_ids(id);
        for (const auto& it : it_vec) {
          truth_counters[it->second].n_velo++;
        }
      }
      else if (lhcb_id::is_ut(id)) {
        n_meas++;
        total_counter.n_ut++;
        const auto it_vec = mc_assoc.find_ids(id);
        for (const auto& it : it_vec) {
          truth_counters[it->second].n_ut++;
        }
      }
      else if (lhcb_id::is_scifi(id)) {
        n_meas++;
        total_counter.n_scifi++;
        const auto it_vec = mc_assoc.find_ids(id);
        for (const auto& it : it_vec) {
          truth_counters[it->second].n_scifi++;
        }
      }
      else {
        debug_cout << "ID not matched to any subdetector " << std::hex << id << std::dec << std::endl;
      }
    }

    // If the Track has total # Velo hits > 2 AND total # SciFi hits > 2, combine matching of mother and daughter
    // particles
    if ((total_counter.n_velo > 2) && (total_counter.n_scifi > 2)) {
      for (auto& id_counter_1 : truth_counters) {
        if ((id_counter_1.second).n_scifi == 0) continue;
        const int mother_key = (mc_assoc.m_mcps[id_counter_1.first]).motherKey;
        for (auto& id_counter_2 : truth_counters) {
          if (&id_counter_1 == &id_counter_2) continue;
          const int key = (mc_assoc.m_mcps[id_counter_2.first]).key;
          if (key == mother_key) {
            if ((id_counter_2.second).n_velo == 0) continue;
            // debug_cout << "\t Particle with key " << key << " and PID " << (mc_assoc.m_mcps[id_counter_1.first]).pid
            // << " is daughter of particle with PID " << (mc_assoc.m_mcps[id_counter_2.first]).pid << std::endl;

            //== Daughter hits are added to mother.
            (id_counter_2.second).n_velo += (id_counter_1.second).n_velo;
            (id_counter_2.second).n_ut += (id_counter_1.second).n_ut;
            (id_counter_2.second).n_scifi += (id_counter_1.second).n_scifi;
            if ((id_counter_2.second).n_velo > total_counter.n_velo)
              (id_counter_2.second).n_velo = total_counter.n_velo;
            if ((id_counter_2.second).n_ut > total_counter.n_ut) (id_counter_2.second).n_ut = total_counter.n_ut;
            if ((id_counter_2.second).n_scifi > total_counter.n_scifi)
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
    auto track_best_matched_MCP = mc_assoc.m_mcps.cend();

    float max_weight = 1e9f;
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
        // debug_cout << "\t Matched track " << i_track << " to MCP " << (mc_assoc.m_mcps[id_counter.first]).key <<
        // std::endl;
        // save matched hits per subdetector
        // -> needed for hit efficiency
        int subdetector_counter = 0;
        if (std::is_same_v<typename T::subdetector_t, Checker::Subdetector::Velo>)
          subdetector_counter = id_counter.second.n_velo;
        else if (std::is_same_v<typename T::subdetector_t, Checker::Subdetector::UT>)
          subdetector_counter = id_counter.second.n_ut;
        else if (std::is_same_v<typename T::subdetector_t, Checker::Subdetector::SciFi>)
          subdetector_counter = id_counter.second.n_scifi;
        const float weight = ((float) counter_sum) / ((float) n_meas);
        const MCAssociator::TrackWithWeight track_weight = {i_track, weight, subdetector_counter};
        assoc_table[(mc_assoc.m_mcps[id_counter.first]).key].push_back(track_weight);
        match = true;

        if (weight < max_weight) {
          max_weight = weight;
          track_best_matched_MCP = mc_assoc.m_mcps.begin() + id_counter.first;
        }
      }
    }

    // if (total_counter.n_scifi > 2) {
    //   if (match) {
    //     std::ofstream ofs_xchi2;
    //     ofs_xchi2.open("good_combined_chi2.txt", std::ofstream::out | std::ofstream::app);
    //     ofs_xchi2 << track.qop << ", ";
    //     ofs_xchi2.close();
    //   } else {
    //     std::ofstream ofs_xchi2;
    //     ofs_xchi2.open("bad_combined_chi2.txt", std::ofstream::out | std::ofstream::app);
    //     ofs_xchi2 << track.qop << ", ";
    //     ofs_xchi2.close();
    //   }
    // }

    return {match, track_best_matched_MCP};
  }

  template<typename T>
  void accumulate_impl(
    const Checker::Tracks& tracks,
    const MCEvent& mc_event)
  {
    for (auto& report : m_categories) {
      report.event_start();
    }

    // register MC particles
    for (auto& report : m_categories) {
      report(mc_event.m_mcps);
    }

    // fill histograms of reconstructible MC particles in various categories
    for (auto& histo_cat : m_histo_categories) {
      m_histos->fillReconstructibleHistos(mc_event.m_mcps, histo_cat);
    }

    MCAssociator mc_assoc {mc_event.m_mcps};
    // linker table between MCParticles and matched tracks with weights
    std::unordered_map<uint32_t, std::vector<MCAssociator::TrackWithWeight>> assoc_table;

    // Match tracks to MCPs
    std::size_t nghostsperevt = 0;
    std::size_t ntracksperevt = 0;
    std::size_t nghoststriggerperevt = 0;
    std::size_t ntrackstriggerperevt = 0;
    for (size_t i_track = 0; i_track < tracks.size(); ++i_track) {
      const auto& track = tracks[i_track];
      m_histos->fillTotalHistos(mc_event.m_mcps.empty() ? 0 : mc_event.m_mcps[0].nPV, static_cast<double>(track.eta));

      auto [match, track_best_matched_MCP] = match_track_to_MCPs<T>(mc_assoc, tracks, i_track, assoc_table);

      ++ntracksperevt;

      const bool triggerCondition = track.p > 3000.f && track.pt > 500.f;
      if (triggerCondition) {
        ntrackstriggerperevt++;
      }
      if (!match) {
        ++nghostsperevt;
        m_histos->fillGhostHistos(mc_event.m_mcps.empty() ? 0 : mc_event.m_mcps[0].nPV, static_cast<double>(track.eta));
        if (triggerCondition) ++nghoststriggerperevt;
        if (track.is_muon) {
          m_histos->fillMuonGhostHistos(
            mc_event.m_mcps.empty() ? 0 : mc_event.m_mcps[0].nPV, static_cast<double>(track.eta));
          ++n_is_muon_ghost;
        }
      }
    }

    // Iterator over MCPs
    // Check which ones were matched to a track
    for (const auto& mcp : mc_event.m_mcps) {
      const auto key = mcp.key;

      // Muon stats
      if (std::abs(mcp.pid) == 13) // muon
        m_n_MCPs_muon++;
      else // not muon
        m_n_MCPs_not_muon++;

      auto tracks_it = assoc_table.find(key);
      if (tracks_it == assoc_table.end()) // no track matched to MCP
        continue;

      m_n_tracks_matched_to_MCP++;

      // have MC association
      // find track with highest weight
      auto const& matched_tracks = tracks_it->second;
      auto track_with_weight = std::max_element(
        matched_tracks.cbegin(),
        matched_tracks.cend(),
        [](const MCAssociator::TrackWithWeight& a, const MCAssociator::TrackWithWeight& b) noexcept {
          return a.m_w < b.m_w;
        });

      auto const& track = tracks[track_with_weight->m_idx];

      // add to various categories
      for (auto& report : m_categories) {
        // report(track, mcp, weight, get_num_hits);
        report(matched_tracks, mcp, get_num_hits_subdetector<typename T::subdetector_t>);
      }

      // Muon ID checker
      muon_id_matching(matched_tracks, mcp, tracks);

      // fill histograms of reconstructible MC particles in various categories
      for (auto& histo_cat : m_histo_categories) {
        m_histos->fillReconstructedHistos(mcp, histo_cat);
      }
      // fill histogram of momentum resolution
      if (
        std::is_same_v<typename T::subdetector_t, Checker::Subdetector::SciFi> && mcp.hasVelo && mcp.hasUT &&
        mcp.hasSciFi) {
        m_histos->fillMomentumResolutionHisto(mcp, track.p, track.qop);
      }
      if (std::is_same_v<typename T::subdetector_t, Checker::Subdetector::UT> && mcp.hasVelo && mcp.hasUT) {
        m_histos->fillMomentumResolutionHisto(mcp, track.p, track.qop);
      }
    }

    for (auto& report : m_categories) {
      report.event_done();
    }

    // almost done, notify of end of event...
    ++m_nevents;

    m_ghostperevent *= float(m_nevents - 1) / float(m_nevents);
    if (ntracksperevt) {
      m_ghostperevent += (float(nghostsperevt) / float(ntracksperevt)) / float(m_nevents);
    }
    m_nghosts += nghostsperevt;
    m_ntracks += ntracksperevt;

    m_ghosttriggerperevent *= float(m_nevents - 1) / float(m_nevents);
    if (ntrackstriggerperevt) {
      m_ghosttriggerperevent += (float(nghoststriggerperevt) / float(ntrackstriggerperevt)) / float(m_nevents);
    }
    m_nghoststrigger += nghoststriggerperevt;
    m_ntrackstrigger += ntrackstriggerperevt;
  }

  const std::vector<Checker::HistoCategory>& histo_categories() const { return m_histo_categories; }

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
  TrackCheckerVelo(CheckerInvoker const* invoker, std::string const& root_file, const std::string& name);
};

struct TrackCheckerVeloUT : public TrackChecker {
  using subdetector_t = Checker::Subdetector::UT;
  TrackCheckerVeloUT(CheckerInvoker const* invoker, std::string const& root_file, const std::string& name);
};

struct TrackCheckerForward : public TrackChecker {
  using subdetector_t = Checker::Subdetector::SciFi;
  TrackCheckerForward(CheckerInvoker const* invoker, std::string const& root_file, const std::string& name);
};
