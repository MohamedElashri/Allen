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
#include "CheckerTracks.cuh"

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
    double m_effperevt = 0.0;
    std::size_t m_naccept_per_event = 0;
    std::size_t m_nfound_per_event = 0;
    std::size_t m_nclones_per_event = 0;
    double m_eff_per_event = 0.0;
    double m_number_of_events = 0.0;
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
