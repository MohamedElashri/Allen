/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
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

void MCEvent::check_mcp(const MCParticle& mcp [[maybe_unused]])
{
  assert(!std::isnan(mcp.p));
  assert(!std::isnan(mcp.pt));
  assert(!std::isnan(mcp.eta));
  assert(!std::isinf(mcp.p));
  assert(!std::isinf(mcp.pt));
  assert(!std::isinf(mcp.eta));
}

MCEvent::MCEvent(std::vector<char> const& particles, std::vector<char> const& vertices, const bool checkEvent)
{
  load_particles(particles);

  if (checkEvent) {
    for (const auto& mcp : m_mcps) {
      check_mcp(mcp);
    }
  }

  load_vertices(vertices);
}

void MCEvent::load_particles(const std::vector<char>& particles)
{
  uint8_t* input = (uint8_t*) particles.data();

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
    p.ovtx_x = *((float*) input);
    input += sizeof(float);
    p.ovtx_y = *((float*) input);
    input += sizeof(float);
    p.ovtx_z = *((float*) input);
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
    p.motherKey = *((uint32_t*) input);
    input += sizeof(uint32_t);
    p.DecayOriginMother_key = *((int*) input);
    input += sizeof(int);
    p.DecayOriginMother_pid = *((int*) input);
    input += sizeof(int);
    p.DecayOriginMother_pt = *((float*) input);
    input += sizeof(float);
    p.DecayOriginMother_tau = *((float*) input);
    input += sizeof(float);
    p.charge = *((float*) input);
    input += sizeof(float);
    p.nPV = *((uint32_t*) input);
    input += sizeof(uint32_t);

    const auto num_Velo_hits = *((uint32_t*) input);
    input += sizeof(uint32_t);
    std::vector<uint32_t> hits;
    std::copy_n((uint32_t*) input, num_Velo_hits, std::back_inserter(hits));
    input += sizeof(uint32_t) * num_Velo_hits;

    p.velo_num_hits = (unsigned) hits.size();

    const auto num_UT_hits = *((uint32_t*) input);
    input += sizeof(uint32_t);
    std::copy_n((uint32_t*) input, num_UT_hits, std::back_inserter(hits));
    input += sizeof(uint32_t) * num_UT_hits;

    p.ut_num_hits = (unsigned) hits.size() - p.velo_num_hits;

    const auto num_SciFi_hits = *((uint32_t*) input);
    input += sizeof(uint32_t);
    std::copy_n((uint32_t*) input, num_SciFi_hits, std::back_inserter(hits));
    input += sizeof(uint32_t) * num_SciFi_hits;

    // Add the mcp to mcps
    p.scifi_num_hits = (unsigned) hits.size() - p.ut_num_hits - p.velo_num_hits;
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

void MCEvent::load_vertices(const std::vector<char>& vertices)
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
    mc_vertex.x = *((double*) input);
    input += sizeof(double);
    mc_vertex.y = *((double*) input);
    input += sizeof(double);
    mc_vertex.z = *((double*) input);
    input += sizeof(double);

    // if(mc_vertex.numberTracks >= 4) vertices.push_back(mc_vertex);
    m_mcvs.push_back(mc_vertex);
  }
}

bool MCEvent::is_subdetector_impl(const LHCbIDs& vector, const LHCbID& id) const
{
  const auto it = std::lower_bound(std::begin(vector), std::end(vector), id);
  if (it != std::end(vector) && *it == id) {
    return true;
  }
  return false;
}
