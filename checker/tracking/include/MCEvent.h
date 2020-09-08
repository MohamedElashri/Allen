/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
/** @file MCEvent.h
 *
 * @brief a reader of MC events
 *
 * @author Rainer Schwemmer
 * @author Daniel Campora
 * @author Manuel Schiller
 * @date 2018-02-18
 *
 * 2018-07 Dorothea vom Bruch: updated to run over different track types,
 * take input from Renato Quagliani's TrackerDumper
 */

#pragma once

#include <cassert>
#include <cstdint>
#include <string>
#include <vector>
#include <algorithm>
#include "MCParticle.h"
#include "Common.h"
#include "Logger.h"
#include "LHCbID.h"
#include "MCVertex.h"
#include "CheckerTypes.h"

struct MCEvent {

  MCVertices m_mcvs;
  MCParticles m_mcps;
  uint32_t size;

  // Constructor
  MCEvent() {};
  MCEvent(std::vector<char> const& _particles, std::vector<char> const& _vertices, const bool checkFile = true);

  // Checks if a LHCb ID is in a particular subdetector
  bool is_subdetector_impl(const LHCbIDs& vector, const LHCbID& id) const;

  // Subdetector-specialized check
  template<typename T>
  bool is_subdetector(const LHCbID& id) const;

  // Checks an MCP does not contain invalid values
  void check_mcp(const MCParticle& mcp);

private:
  void load_particles(std::vector<char> const& particles);

  void load_vertices(std::vector<char> const& vertices);
};

using MCEvents = std::vector<MCEvent>;
