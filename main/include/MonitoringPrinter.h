/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "Logger.h"

#ifndef ALLEN_STANDALONE
#include "Gaudi/Accumulators.h"
#include "Gaudi/MonitoringHub.h"
#endif

#include <deque>

#ifdef ALLEN_STANDALONE
struct MonitoringPrinter {
  MonitoringPrinter(unsigned = 0, bool = true) {}
  void process(bool = false) {}
};
#else
struct MonitoringPrinter : public Gaudi::Monitoring::Hub::Sink {
  using Entity = Gaudi::Monitoring::Hub::Entity;

  MonitoringPrinter(unsigned int printPeriod = 10, bool do_print = true) : m_printPeriod(printPeriod), m_print(do_print)
  {}

  virtual void registerEntity(Entity ent) override { m_entities.push_back(ent); }

  virtual void removeEntity(Entity const&) override
  {
    // auto it = std::find(begin(m_entities), end(m_entities), ent);
    // if (it != m_entities.end()) m_entities.erase(it);
  }

  void process(bool forcePrint = false)
  {
    if (m_print && (++m_delayCount >= m_printPeriod || forcePrint)) {
      m_delayCount = 0;
      for (auto entity : m_entities) {
        auto json = entity.toJSON();
        info_cout << entity.component << ":" << entity.name;
        if (json.count("nEntries")) {
          info_cout << "\tEntries: " << json["nEntries"];
        }
        info_cout << std::endl;
      }
    }
  }

private:
  std::deque<Entity> m_entities;

  unsigned int m_printPeriod;
  unsigned int m_delayCount {0};
  bool m_print;
};
#endif
