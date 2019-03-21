/** @file velopix-input-reader.cpp
 *
 * @brief reader of velopix input files
 *
 * @author Rainer Schwemmer
 * @author Daniel Campora
 * @author Manuel Schiller
 * @date 2018-02-08
 *
 * 2018-07 Dorothea vom Bruch: updated to run over different track types,
 * take input from Renato Quagliani's TrackerDumper
 */

#include "MCEvent.h"

void MCEvent::check_mcp(const MCParticle& mcp) {
  assert(!std::isnan(mcp.p));
  assert(!std::isnan(mcp.pt));
  assert(!std::isnan(mcp.eta));
  assert(!std::isinf(mcp.p));
  assert(!std::isinf(mcp.pt));
  assert(!std::isinf(mcp.eta));
}

MCEvent::MCEvent(const std::vector<char>& event, const bool checkEvent)
{
  uint8_t* input = (uint8_t*) event.data();

  uint32_t number_mcp = *((uint32_t*) input);
  input += sizeof(uint32_t);
  // debug_cout << "num MCPs = " << number_mcp << std::endl;
  for (uint32_t i = 0; i < number_mcp; ++i) {
    MCParticle p;
    p.key = *((uint32_t*) input);
    input += sizeof(uint32_t);
    p.pid = *((uint32_t*) input);
    input += sizeof(uint32_t);
    p.p = *((float*) input);
    input += sizeof(float);
    p.pt = *((float*) input);
    input += sizeof(float);
    p.eta = *((float*) input);
    input += sizeof(float);
    p.phi = *((float*) input);
    input += sizeof(float);
    p.isLong = (bool) *((int8_t*) input);
    input += sizeof(int8_t);
    p.isDown = (bool) *((int8_t*) input);
    input += sizeof(int8_t);
    p.hasVelo = (bool) *((int8_t*) input);
    input += sizeof(int8_t);
    p.hasUT = (bool) *((int8_t*) input);
    input += sizeof(int8_t);
    p.hasSciFi = (bool) *((int8_t*) input);
    input += sizeof(int8_t);
    p.fromBeautyDecay = (bool) *((int8_t*) input);
    input += sizeof(int8_t);
    p.fromCharmDecay = (bool) *((int8_t*) input);
    input += sizeof(int8_t);
    p.fromStrangeDecay = (bool) *((int8_t*) input);
    input += sizeof(int8_t);
    p.nPV = *((uint32_t*) input);
    input += sizeof(uint32_t);

    const auto num_Velo_hits = *((uint32_t*) input);
    input += sizeof(uint32_t);
    std::vector<uint32_t> hits;
    std::copy_n((uint32_t*) input, num_Velo_hits, std::back_inserter(hits));
    std::copy_n((uint32_t*) input, num_Velo_hits, std::back_inserter(m_velo_lhcb_ids));
    input += sizeof(uint32_t) * num_Velo_hits;

    const auto num_UT_hits = *((uint32_t*) input);
    input += sizeof(uint32_t);
    std::copy_n((uint32_t*) input, num_UT_hits, std::back_inserter(hits));
    std::copy_n((uint32_t*) input, num_UT_hits, std::back_inserter(m_ut_lhcb_ids));
    input += sizeof(uint32_t) * num_UT_hits;

    const auto num_SciFi_hits = *((uint32_t*) input);
    input += sizeof(uint32_t);
    std::copy_n((uint32_t*) input, num_SciFi_hits, std::back_inserter(hits));
    std::copy_n((uint32_t*) input, num_SciFi_hits, std::back_inserter(m_scifi_lhcb_ids));
    input += sizeof(uint32_t) * num_SciFi_hits;

    // Add the mcp to mcps
    p.numHits = (uint) hits.size();
    p.hits = hits;
    if (num_Velo_hits > 0 || num_UT_hits > 0 || num_SciFi_hits > 0) {
      m_mcps.push_back(p);
    }
  }

  size = input - (uint8_t*) event.data();

  if (size != event.size()) {
    throw StrException(
      "Size mismatch in event deserialization: " + std::to_string(size) + " vs " + std::to_string(event.size()));
  }

  if (checkEvent) {
    for (const auto& mcp : m_mcps) {
      check_mcp(mcp);
    }
  }

  // Sort the LHCb IDs
  std::sort(std::begin(m_velo_lhcb_ids), std::end(m_velo_lhcb_ids));
  std::sort(std::begin(m_ut_lhcb_ids), std::end(m_ut_lhcb_ids));
  std::sort(std::begin(m_scifi_lhcb_ids), std::end(m_scifi_lhcb_ids));
}

bool MCEvent::is_subdetector_impl(const LHCbIDs& vector, const LHCbID& id) const {
  const auto it = std::lower_bound(std::begin(vector), std::end(vector), id);
  if (it != std::end(vector) && *it == id) {
    return true;
  }
  return false;
}

template<>
bool MCEvent::is_subdetector<Checker::Subdetector::Velo>(const LHCbID& id) const {
  return is_subdetector_impl(m_velo_lhcb_ids, id);
}

template<>
bool MCEvent::is_subdetector<Checker::Subdetector::UT>(const LHCbID& id) const {
  return is_subdetector_impl(m_ut_lhcb_ids, id);
}

template<>
bool MCEvent::is_subdetector<Checker::Subdetector::SciFi>(const LHCbID& id) const {
  return is_subdetector_impl(m_scifi_lhcb_ids, id);
}
