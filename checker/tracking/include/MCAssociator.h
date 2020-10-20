/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
/** @file MCAssociator.h
 *
 * @brief a simple MC associator
 *
 * @author Rainer Schwemmer
 * @author Daniel Campora
 * @author Manuel Schiller
 * @date 2018-02-18
 */

#pragma once

#include <map>
#include <vector>
#include <utility>
#include <algorithm>
#include <numeric>
#include "LHCbID.h"
#include "MCParticle.h"
#include "Logger.h"

/// simple MC associator
struct MCAssociator {
  using LHCbIDWithIndex = std::pair<LHCbID, unsigned>;
  using AssocMap = std::vector<LHCbIDWithIndex>;

  /// internal structure with index into particles and weight
  struct MCParticleWithWeight {
    std::size_t m_idx;
    float m_w;
    unsigned m_counter_sum;
    MCParticleWithWeight(std::size_t idx, float w, unsigned counter_sum) :
      m_idx(idx), m_w(w), m_counter_sum(counter_sum)
    {}
    MCParticleWithWeight(const MCParticleWithWeight&) = default;
    MCParticleWithWeight(MCParticleWithWeight&&) = default;
    MCParticleWithWeight& operator=(const MCParticleWithWeight&) = default;
    MCParticleWithWeight& operator=(MCParticleWithWeight&&) = default;
  };
  // internal structure with index into tracks matched to an MCP
  struct TrackWithWeight {
    int m_idx;
    float m_w;
    int m_counter_subdetector;
    TrackWithWeight(int idx, float w, int counter_subdetector) :
      m_idx(idx), m_w(w), m_counter_subdetector(counter_subdetector)
    {}
    TrackWithWeight(const TrackWithWeight&) = default;
    TrackWithWeight(TrackWithWeight&&) = default;
    TrackWithWeight& operator=(const TrackWithWeight&) = default;
    TrackWithWeight& operator=(TrackWithWeight&&) = default;
  };
  const MCParticles& m_mcps; // keep a reference to MCParticles
  AssocMap m_map;            // association LHCbID -> MCParticle index

  // little helper which does the hard work
  AssocMap::const_iterator find_id(const LHCbID&) const noexcept;
  AssocMap::const_iterator find_id(const LHCbID&, const AssocMap::const_iterator& begin) const noexcept;
  std::vector<AssocMap::const_iterator> find_ids(const LHCbID&) const noexcept;

  MCAssociator(const MCParticles& mcps);
  MCAssociator(const MCAssociator&) = default;
  MCAssociator(MCAssociator&&) = default;

  /// result of an MC association
  class MCAssocResult {
  private:
    using AssocVector = std::vector<MCParticleWithWeight>;
    using AssocTable = std::map<MCParticle, std::vector<TrackWithWeight>>;
    AssocVector m_assoc;
    const MCParticles& m_mcps;

  public:
    MCAssocResult(AssocVector&& assocs, const MCParticles& mcps) : m_assoc(assocs), m_mcps(mcps) {}
    MCAssocResult(const MCAssocResult&) = default;
    MCAssocResult(MCAssocResult&&) = default;

    bool empty() const noexcept { return m_assoc.empty(); }
    operator bool() const noexcept { return !empty(); }
    std::size_t size() const noexcept { return m_assoc.size(); }

    /// something to iterate over a MCAssocResult
    class iterator : private AssocVector::const_iterator {
    private:
      const MCParticles& m_mcps;

    public:
      iterator(AssocVector::const_iterator it, const MCParticles& mcps) : AssocVector::const_iterator(it), m_mcps(mcps)
      {}
      iterator(const iterator&) = default;
      iterator(iterator&&) = default;
      iterator& operator++() noexcept
      {
        ++reinterpret_cast<AssocVector::const_iterator&>(*this);
        return *this;
      }
      iterator operator++(int) noexcept
      {
        auto retVal(*this);
        ++reinterpret_cast<AssocVector::const_iterator&>(*this);
        return retVal;
      }
      iterator& operator--() noexcept
      {
        --reinterpret_cast<AssocVector::const_iterator&>(*this);
        return *this;
      }
      iterator operator--(int) noexcept
      {
        auto retVal(*this);
        --reinterpret_cast<AssocVector::const_iterator&>(*this);
        return retVal;
      }
      bool operator==(const iterator& other) const noexcept
      {
        const auto& a = reinterpret_cast<const AssocVector::const_iterator&>(*this);
        const auto& b = reinterpret_cast<const AssocVector::const_iterator&>(other);
        return a == b;
      }
      bool operator!=(const iterator& other) const noexcept
      {
        const auto& a = reinterpret_cast<const AssocVector::const_iterator&>(*this);
        const auto& b = reinterpret_cast<const AssocVector::const_iterator&>(other);
        return a != b;
      }
      bool operator<(const iterator& other) const noexcept
      {
        const auto& a = reinterpret_cast<const AssocVector::const_iterator&>(*this);
        const auto& b = reinterpret_cast<const AssocVector::const_iterator&>(other);
        return a < b;
      }
      bool operator<=(const iterator& other) const noexcept
      {
        const auto& a = reinterpret_cast<const AssocVector::const_iterator&>(*this);
        const auto& b = reinterpret_cast<const AssocVector::const_iterator&>(other);
        return a <= b;
      }
      bool operator>(const iterator& other) const noexcept
      {
        const auto& a = reinterpret_cast<const AssocVector::const_iterator&>(*this);
        const auto& b = reinterpret_cast<const AssocVector::const_iterator&>(other);
        return a > b;
      }
      bool operator>=(const iterator& other) const noexcept
      {
        const auto& a = reinterpret_cast<const AssocVector::const_iterator&>(*this);
        const auto& b = reinterpret_cast<const AssocVector::const_iterator&>(other);
        return a >= b;
      }
      std::tuple<MCParticles::const_reference, float, int> operator*() const noexcept
      {
        AssocVector::const_reference ref = reinterpret_cast<const AssocVector::const_iterator&>(*this).operator*();
        return std::tuple<MCParticles::const_reference, float, int> {m_mcps[ref.m_idx], ref.m_w, ref.m_counter_sum};
      }
    };
    iterator begin() const noexcept { return iterator(m_assoc.begin(), m_mcps); }
    iterator end() const noexcept { return iterator(m_assoc.end(), m_mcps); }
    std::tuple<MCParticles::const_reference, float, int> front() const noexcept { return *begin(); }
    std::tuple<MCParticles::const_reference, float, int> back() const noexcept { return *--end(); }
  };

  // private:
  using AssocPreResult = std::map<std::size_t, std::size_t>;
  /// little helper for the final step of multi-MCP association
  MCAssocResult buildResult(const AssocPreResult& assocmap, std::size_t total) const noexcept;

  // public:
  /// associate a single LHCbID
  MCAssocResult operator()(LHCbID id) const noexcept
  {
    auto it = find_id(id);
    if (m_map.end() == it) return MCAssocResult({}, m_mcps);
    return MCAssocResult({{it->second, 1.f, 1}}, m_mcps);
  }
  /// associate a range of LHCbIDs
  template<typename IT>
  MCAssocResult operator()(IT first, IT last, std::size_t& n_matched_total) const noexcept
  {
    AssocPreResult assoc;
    // count how often each particle appears
    // and how many hits of the reconstructed track are matched
    // to the MCP
    for (; last != first; ++first) {
      const auto it = find_id(*first);
      if (it == m_map.end()) continue;
      // std::cout << "Matched LHCbID to MCP: " << *first << " to " << it->second << std::endl;
      ++n_matched_total;
      ++assoc[it->second];
    }

    // bring the map into a more compact format
    return buildResult(assoc, n_matched_total);
  }
};
