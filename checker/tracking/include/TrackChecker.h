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

#ifdef WITH_ROOT
#include "TDirectory.h"
#include "TFile.h"
#include "TH1D.h"
#include "TH2D.h"
#endif

class TrackChecker {
protected:
  bool m_print = false;

  using AcceptFn = std::function<bool(MCParticles::const_reference&)>;
  struct TrackEffReport {
    std::string m_name;
    AcceptFn m_accept;
    std::size_t m_naccept = 0;
    std::size_t m_nfound = 0;
    std::size_t m_nacceptperevt = 0;
    std::size_t m_nfoundperevt = 0;
    std::size_t m_nclones = 0;
    std::size_t m_nevents = 0;
    float m_effperevt = 0.f;
    float m_hitpur = 0.f;
    float m_hiteff = 0.f;
    std::set<uint32_t> m_keysseen;

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
      const std::function<uint32_t(const MCParticle&)>& get_num_hits);
    /// notify of end of event
    void evtEnds();
    /// free resources, and print result
    ~TrackEffReport();
  };

  struct HistoCategory {
    std::string m_name;
    AcceptFn m_accept;
    std::set<uint32_t> m_keysseen;

    /// construction from name and accept criterion for eff. denom.
    template<typename F>
    HistoCategory(const std::string& name, const F& accept) : m_name(name), m_accept(accept)
    {}
    /// construction from name and accept criterion for eff. denom.
    template<typename F>
    HistoCategory(std::string&& name, F&& accept) : m_name(std::move(name)), m_accept(std::move(accept))
    {}
    /// notify of end of event
    void evtEnds();
  };

  std::vector<TrackEffReport> m_categories;
  std::vector<HistoCategory> m_histo_categories;
  std::string m_trackerName = "";

  struct Histos {
#ifdef WITH_ROOT
    std::map<std::string, TH1D*> h_reconstructible_eta;
    std::map<std::string, TH1D*> h_reconstructible_p;
    std::map<std::string, TH1D*> h_reconstructible_pt;
    std::map<std::string, TH1D*> h_reconstructible_phi;
    std::map<std::string, TH1D*> h_reconstructible_nPV;
    std::map<std::string, TH1D*> h_reconstructed_eta;
    std::map<std::string, TH1D*> h_reconstructed_p;
    std::map<std::string, TH1D*> h_reconstructed_pt;
    std::map<std::string, TH1D*> h_reconstructed_phi;
    std::map<std::string, TH1D*> h_reconstructed_nPV;

    TH1D* h_ghost_nPV;
    TH1D* h_total_nPV;
    TH2D* h_dp_versus_p;
    TH2D* h_momentum_resolution;
    TH2D* h_qop_resolution;
    TH2D* h_dqop_versus_qop;
    TH1D* h_momentum_matched;
#endif
    void initHistos(const std::vector<HistoCategory>& histo_categories);
    void fillReconstructibleHistos(const MCParticles& mcps, const HistoCategory& category);
    void fillReconstructedHistos(const MCParticle& mcp, HistoCategory& category);
    void fillTotalHistos(const MCParticle& mcp);
    void fillGhostHistos(const MCParticle& mcp);
    void fillMomentumResolutionHisto(const MCParticle& mcp, const float p, const float qop);
    void deleteHistos(const std::vector<HistoCategory>& histo_categories);
  };

  const float m_minweight = 0.7f;
  std::size_t m_nevents = 0;
  std::size_t m_ntracks = 0;
  std::size_t m_nghosts = 0;
  float m_ghostperevent = 0.f;

  virtual void SetHistoCategories() = 0;
  virtual void SetCategories() = 0;

public:
  TrackChecker() {};
  ~TrackChecker();
  std::vector<uint32_t> operator()(const Checker::Tracks &tracks, const MCEvent &mc_event,
    const std::function<uint32_t(const MCParticle&)>& get_num_hits);
  const std::vector<HistoCategory>& histo_categories() const {
    return m_histo_categories;
  }
  bool match_track_to_MCPs(
    MCAssociator mc_assoc,
    const Checker::Tracks& tracks,
    const int i_track,
    std::map<uint32_t, std::vector<MCAssociator::TrackWithWeight> >& assoc_table);
      
  Histos histos;
};

struct TrackCheckerVelo : public TrackChecker {
  using subdetector_t = Checker::Subdetector::Velo;

  void SetCategories();
  void SetHistoCategories();
  TrackCheckerVelo()
  {
    SetCategories();
    SetHistoCategories();
    m_trackerName = "Velo";
  };
};

struct TrackCheckerVeloUT : public TrackChecker {
  using subdetector_t = Checker::Subdetector::UT;

  void SetCategories();
  void SetHistoCategories();
  TrackCheckerVeloUT()
  {
    SetCategories();
    SetHistoCategories();
    m_trackerName = "VeloUT";
  };
};

struct TrackCheckerForward : public TrackChecker {
  using subdetector_t = Checker::Subdetector::SciFi;
  
  void SetCategories();
  void SetHistoCategories();
  TrackCheckerForward()
  {
    m_print = true;
    SetCategories();
    SetHistoCategories();
    m_trackerName = "Forward";
  };
};
