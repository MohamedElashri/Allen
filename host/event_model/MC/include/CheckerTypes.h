/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
/** @file Tracks.h
 *
 * @brief SOA Velo Tracks
 *
 * @author Rainer Schwemmer
 * @author Daniel Campora
 * @author Manuel Schiller
 * @date 2018-02-06
 */

#pragma once

#include <array>
#include <cstdint>

#include "LHCbID.h"
#include "MCEvent.h"
#include "MCAssociator.h"

namespace Checker {

  struct BaseChecker {
    virtual void report(size_t n_events) const = 0;
    virtual ~BaseChecker() = default;
  };

  namespace Subdetector {
    struct Velo {
    };
    struct UT {
    };
    struct SciFi {
    };
    struct Muon {
    };

    template<typename T>
    using muon_as_scifi_t = std::conditional_t<std::is_same_v<T, Muon>, SciFi, T>;
  } // namespace Subdetector

  struct TruthCounter {
    unsigned n_velo {0};
    unsigned n_ut {0};
    unsigned n_scifi {0};
  };

  struct Track {
    LHCbIDs allids = {};
    // Kalman information.
    float z = 0.f, x = 0.f, y = 0.f, tx = 0.f, ty = 0.f, qop = 0.f;
    float first_qop = 0.f, best_qop = 0.f;
    float chi2 = 0.f, chi2V = 0.f, chi2T = 0.f;
    unsigned ndof = 0, ndofV = 0, ndofT = 0;
    float kalman_ip = 0.f, kalman_ip_chi2 = 0.f, kalman_ipx = 0.f, kalman_ipy = 0.f;
    float kalman_docaz = 0.f;
    float velo_ip = 0.f, velo_ip_chi2 = 0.f, velo_ipx = 0.f, velo_ipy = 0.f;
    float velo_docaz = 0.f;
    float long_ip = 0.f, long_ip_chi2 = 0.f, long_ipx = 0.f, long_ipy = 0.f;
    std::size_t n_matched_total = 0;
    float p = 0.f, pt = 0.f, eta = 0.f;
    float muon_catboost_output = 0.f;
    bool is_muon = false;

    void addId(LHCbID id) { allids.push_back(id); }

    LHCbIDs ids() const { return allids; }

    int nIDs() const { return allids.size(); }
  };

  using Tracks = std::vector<Track>;

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
    std::size_t m_naccept_per_event = 0;
    std::size_t m_nfound_per_event = 0;
    std::size_t m_nclones_per_event = 0;
    float m_eff_per_event = 0.f;
    float m_number_of_events = 0.f;
    std::vector<double> m_hitpurs = {};
    std::vector<double> m_hiteffs = {};

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
      const std::vector<MCAssociator::TrackWithWeight>& tracks,
      MCParticles::const_reference& mcp,
      const std::function<uint32_t(const MCParticle&)>& get_num_hits_subdetector);

    void event_start();
    void event_done();

    /// print result
    void report() const;
  };

} // namespace Checker
