/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
/** @file MCEvent.cpp
 *
 * @brief reader of MC input files
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

void MCEvent::check_mcp(const MCParticle& mcp [[maybe_unused]])
{
  assert(!std::isnan(mcp.p));
  assert(!std::isnan(mcp.pt));
  assert(!std::isnan(mcp.eta));
  assert(!std::isinf(mcp.p));
  assert(!std::isinf(mcp.pt));
  assert(!std::isinf(mcp.eta));
}

MCEvent::MCEvent(
  std::vector<char> const& particles,
  std::vector<char> const& vertices,
  const bool checkEvent,
  const uint32_t bankVersion)
{
  load_particles(particles, bankVersion);
  if (checkEvent) {
    for (const auto& mcp : m_mcps) {
      check_mcp(mcp);
    }
  }

  load_vertices(vertices, bankVersion);
}

void MCEvent::load_particles(const std::vector<char>& particles, const uint32_t bankVersion)
{
  uint8_t* input = (uint8_t*) particles.data();

  uint32_t number_mcp = *((uint32_t*) input);
  input += sizeof(uint32_t);
  debug_cout << "num MCPs = " << number_mcp << std::endl;
  for (uint32_t i = 0; i < number_mcp; ++i) {
    MCParticle p;
    std::memcpy(&(p.key), input, sizeof(uint32_t));
    input += sizeof(uint32_t);
    std::memcpy(&(p.pid), input, sizeof(uint32_t));
    input += sizeof(uint32_t);
    std::memcpy(&(p.p), input, sizeof(float));
    input += sizeof(float);
    std::memcpy(&(p.pt), input, sizeof(float));
    input += sizeof(float);
    std::memcpy(&(p.eta), input, sizeof(float));
    input += sizeof(float);
    std::memcpy(&(p.phi), input, sizeof(float));
    input += sizeof(float);
    std::memcpy(&(p.ovtx_x), input, sizeof(float));
    input += sizeof(float);
    std::memcpy(&(p.ovtx_y), input, sizeof(float));
    input += sizeof(float);
    std::memcpy(&(p.ovtx_z), input, sizeof(float));
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
    if (bankVersion >= 2) {
      p.fromSignal = (bool) *((int8_t*) input);
      input += sizeof(int8_t);
    }

    std::memcpy(&(p.motherKey), input, sizeof(int));
    input += sizeof(int);
    std::memcpy(&(p.mother_pid), input, sizeof(int));
    input += sizeof(int);
    std::memcpy(&(p.DecayOriginMother_key), input, sizeof(int));
    input += sizeof(int);
    std::memcpy(&(p.DecayOriginMother_pid), input, sizeof(int));
    input += sizeof(int);
    std::memcpy(&(p.DecayOriginMother_pt), input, sizeof(float));
    input += sizeof(float);
    std::memcpy(&(p.DecayOriginMother_tau), input, sizeof(float));
    input += sizeof(float);
    std::memcpy(&(p.charge), input, sizeof(float));
    input += sizeof(float);
    std::memcpy(&(p.nPV), input, sizeof(uint32_t));
    input += sizeof(uint32_t);

    std::memcpy(&(p.velo_num_hits), input, sizeof(uint32_t));
    const auto num_Velo_hits = p.velo_num_hits;
    input += sizeof(uint32_t);
    std::vector<uint32_t> hits(num_Velo_hits);
    if (num_Velo_hits > 0) std::memcpy(hits.data(), input, sizeof(uint32_t) * num_Velo_hits);
    input += sizeof(uint32_t) * num_Velo_hits;

    std::memcpy(&(p.ut_num_hits), input, sizeof(uint32_t));
    const auto num_UT_hits = p.ut_num_hits;
    input += sizeof(uint32_t);
    hits.resize(num_Velo_hits + num_UT_hits);
    if (num_UT_hits > 0) std::memcpy(hits.data() + num_Velo_hits, input, sizeof(uint32_t) * num_UT_hits);
    input += sizeof(uint32_t) * num_UT_hits;

    std::memcpy(&(p.scifi_num_hits), input, sizeof(uint32_t));
    const auto num_SciFi_hits = p.scifi_num_hits;
    input += sizeof(uint32_t);
    hits.resize(num_Velo_hits + num_UT_hits + num_SciFi_hits);
    if (num_SciFi_hits > 0)
      std::memcpy(hits.data() + num_Velo_hits + num_UT_hits, input, sizeof(uint32_t) * num_SciFi_hits);
    input += sizeof(uint32_t) * num_SciFi_hits;

    // Add the mcp to mcps
    p.numHits = (unsigned) hits.size();
    p.hits = hits;
    if (num_Velo_hits > 0 || num_UT_hits > 0 || num_SciFi_hits > 0) {
      m_mcps.push_back(p);
    }
  }
  size = input - (uint8_t*) particles.data();

  if (size != particles.size()) {
    throw StrException(
      "Size mismatch in event deserialization: " + std::to_string(size) + " vs " + std::to_string(particles.size()));
  }
}

void MCEvent::load_vertices(const std::vector<char>& vertices, const uint32_t /*bankVersion*/)
{
  // collect true PV vertices in a event
  uint8_t* input = (uint8_t*) vertices.data();

  int number_mcpv = *((int*) input);
  input += sizeof(int);

  for (int i = 0; i < number_mcpv; ++i) {
    MCVertex mc_vertex;

    int VertexNumberOfTracks = *((int*) input);
    input += sizeof(int);
    mc_vertex.numberTracks = VertexNumberOfTracks;

    std::memcpy(&(mc_vertex.x), input, sizeof(double));
    input += sizeof(double);
    std::memcpy(&(mc_vertex.y), input, sizeof(double));
    input += sizeof(double);
    std::memcpy(&(mc_vertex.z), input, sizeof(double));
    input += sizeof(double);

    // if(mc_vertex.numberTracks >= 4) vertices.push_back(mc_vertex);
    m_mcvs.push_back(mc_vertex);
  }
}

bool MCEvent::is_subdetector_impl(const LHCbID (&array)[42], const LHCbID& id) const
{
  const auto it = std::lower_bound(std::begin(array), std::end(array), id);
  if (it != std::end(array) && *it == id) {
    return true;
  }
  return false;
}
