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
#include <string>
#include <vector>
#include "Logger.h"
#include "MCAssociator.h"
#include "CheckerTypes.h"
#include "MCEvent.h"

#include "ROOTHeaders.h"

struct TrackCheckerHistos;

namespace Checker {
  using AcceptFn = std::function<bool(MCParticles::const_reference&)>;

  struct HistoCategory {
    std::string m_name;
    AcceptFn m_accept;

    /// construction from name and accept criterion for eff. denom.
    template<typename F>
    HistoCategory(const std::string& name, const F& accept) : m_name(name), m_accept(accept)
    {}
    /// construction from name and accept criterion for eff. denom.
    template<typename F>
    HistoCategory(std::string&& name, F&& accept) : m_name(std::move(name)), m_accept(std::move(accept))
    {}
  };

  struct TrackEffReport {
    std::string m_name;
    Checker::AcceptFn m_accept;
    std::size_t m_naccept = 0;
    std::size_t m_nfound = 0;
    std::size_t m_nacceptperevt = 0;
    std::size_t m_nfoundperevt = 0;
    std::size_t m_nclones = 0;
    std::size_t m_nevents = 0;
    float m_effperevt = 0.f;
    float m_hitpur = 0.f;
    float m_hiteff = 0.f;
    std::size_t m_naccept_per_event = 0;
    std::size_t m_nfound_per_event = 0;
    std::size_t m_nclones_per_event = 0;
    float m_eff_per_event = 0.f;
    float m_number_of_events = 0.f;

    /// no default construction
    TrackEffReport() = delete;
    /// usual copy construction
    TrackEffReport(const TrackEffReport&) = default;
    /// usual move construction
    TrackEffReport(TrackEffReport&&) = default;
    /// usual copy assignment
    TrackEffReport& operator=(const TrackEffReport&) = default;
    /// usual move assignment
    TrackEffReport& operator=(TrackEffReport&&) = default;
    /// construction from name and accept criterion for eff. denom.
    template<typename F>
    TrackEffReport(const std::string& name, const F& accept) : m_name(name), m_accept(accept)
    {}
    /// construction from name and accept criterion for eff. denom.
    template<typename F>
    TrackEffReport(std::string&& name, F&& accept) : m_name(std::move(name)), m_accept(std::move(accept))
    {}
    /// register MC particles
    void operator()(const MCParticles& mcps);
    /// register track and its MC association
    void operator()(
      const std::vector<MCAssociator::TrackWithWeight> tracks,
      MCParticles::const_reference& mcp,
      const std::function<uint32_t(const MCParticle&)>& get_num_hits_subdetector);

    void event_start();
    void event_done();

    /// free resources, and print result
    ~TrackEffReport();
  };
}

class TrackChecker {
protected:
  bool m_print = false;

  std::vector<Checker::TrackEffReport> m_categories;
  std::vector<Checker::HistoCategory> m_histo_categories;
  std::string m_trackerName = "";
  bool m_create_file = false;

  const float m_minweight = 0.7f;
  std::size_t m_nevents = 0;
  std::size_t m_ntracks = 0;
  std::size_t m_nghosts = 0;
  float m_ghostperevent = 0.f;
  float m_ghosttriggerperevent = 0.f;
  std::size_t m_ntrackstrigger = 0;
  std::size_t m_nghoststrigger = 0;

  std::size_t n_is_muon_true = 0;
  std::size_t n_is_muon_misID = 0;
  std::size_t n_matched_muons = 0;
  std::size_t n_matched_not_muons = 0;
  std::size_t n_is_muon_ghost = 0;
  
public:
  TrackChecker(std::string name, std::vector<Checker::TrackEffReport> categories,
               std::vector<Checker::HistoCategory> histo_categories, bool create_file,
               bool print = false);
  ~TrackChecker();
  std::vector<uint32_t> operator()(
    const Checker::Tracks& tracks,
    const MCEvent& mc_event,
    const std::function<uint32_t(const MCParticle&)>& get_num_hits_subdetector);
  const std::vector<Checker::HistoCategory>& histo_categories() const { return m_histo_categories; }
  bool match_track_to_MCPs(
    MCAssociator mc_assoc,
    const Checker::Tracks& tracks,
    const int i_track,
    std::map<uint32_t, std::vector<MCAssociator::TrackWithWeight>>& assoc_table,
    uint32_t& track_best_matched_MCP);

  void muon_id_matching(
      const std::vector<MCAssociator::TrackWithWeight> tracks_with_weight,
      MCParticles::const_reference& mcp,
      const Checker::Tracks& tracks );
  
  TrackCheckerHistos* histos = nullptr;
};

struct TrackCheckerVelo : public TrackChecker {
  using subdetector_t = Checker::Subdetector::Velo;
  TrackCheckerVelo(bool cf);
};

struct TrackCheckerVeloUT : public TrackChecker {
  using subdetector_t = Checker::Subdetector::UT;
  TrackCheckerVeloUT(bool cf);
};

struct TrackCheckerForward : public TrackChecker {
  using subdetector_t = Checker::Subdetector::SciFi;
  TrackCheckerForward(bool cf);

};
