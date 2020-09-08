/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
/** @file MCAssociator.cpp
 *
 * @brief a simple MC associator
 *
 * @author Rainer Schwemmer
 * @author Daniel Campora
 * @author Manuel Schiller
 * @date 2018-02-18
 */

#include "MCAssociator.h"

MCAssociator::MCAssociator(const MCParticles& mcps) : m_mcps(mcps)
{
  // work out how much space we need
  const std::size_t total = std::accumulate(
    mcps.begin(), mcps.end(), 0, [](std::size_t acc, MCParticles::const_reference mcp) noexcept {
      return acc + mcp.numHits;
    });
  m_map.reserve(total);
  // build association LHCbID -> MCParticle index
  std::size_t idx = 0;
  for (auto mcp : mcps) {
    for (auto id : mcp.hits) {
      m_map.emplace_back(id, idx);
    }
    ++idx;
  }
  // sort map by LHCbID for fast lookups
  std::sort(
    m_map.begin(), m_map.end(), [](const LHCbIDWithIndex& a, const LHCbIDWithIndex& b) noexcept {
      return a.first < b.first;
    });
}

MCAssociator::AssocMap::const_iterator MCAssociator::find_id(const LHCbID& id) const noexcept
{
  auto it = std::lower_bound(
    m_map.begin(), m_map.end(), id, [](const LHCbIDWithIndex& a, const LHCbID& b) noexcept { return a.first < b; });

  if (it != m_map.end() && id != it->first) {
    it = m_map.end();
  }

  return it;
}

MCAssociator::AssocMap::const_iterator MCAssociator::find_id(
  const LHCbID& id,
  const MCAssociator::AssocMap::const_iterator& begin) const noexcept
{
  auto it = std::lower_bound(
    begin, m_map.end(), id, [](const LHCbIDWithIndex& a, const LHCbID& b) noexcept { return a.first < b; });

  if (it != m_map.end() && id != it->first) {
    it = m_map.end();
  }

  return it;
}

std::vector<MCAssociator::AssocMap::const_iterator> MCAssociator::find_ids(const LHCbID& id) const noexcept
{
  std::vector<MCAssociator::AssocMap::const_iterator> matched_MCPs;
  for (auto it = find_id(id, m_map.begin()); it != m_map.end(); it = find_id(id, it + 1)) {
    matched_MCPs.push_back(it);
  }

  return matched_MCPs;
}

MCAssociator::MCAssocResult MCAssociator::buildResult(const MCAssociator::AssocPreResult& assocmap, std::size_t total)
  const noexcept
{
  std::vector<MCParticleWithWeight> retVal;
  retVal.reserve(assocmap.size());
  for (auto&& el : assocmap)
    retVal.emplace_back(el.first, float(el.second) / float(total), total);
  // sort such that high weights come first
  std::sort(
    retVal.begin(), retVal.end(), [](const MCParticleWithWeight& a, const MCParticleWithWeight& b) noexcept {
      return a.m_w > b.m_w;
    });
  return MCAssocResult {std::move(retVal), m_mcps};
}
