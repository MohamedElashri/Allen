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

#include "ServiceLocator.h"

#ifndef ALLEN_STANDALONE
#include "Gaudi/Accumulators.h"
#include "Gaudi/Accumulators/Histogram.h"
#include "Gaudi/MonitoringHub.h"

#include <GaudiKernel/Bootstrap.h>
#include "GaudiKernel/ISvcLocator.h"
#endif

#include <deque>

#ifdef ALLEN_STANDALONE
struct MonitoringAggregator {
  void process() {}
};
#else
struct MonitoringAggregator : public Gaudi::Monitoring::Hub::Sink {
  using Entity = Gaudi::Monitoring::Hub::Entity;
  using Sink = Gaudi::Monitoring::Hub::Sink;

  struct Aggregation {
    std::deque<Entity> sources;
  };

  virtual void registerEntity(Entity ent) override { m_incoming_entities.push(ent); }

  virtual void removeEntity(Entity const& ent) override
  {
    auto idStr = ent.type + ":" + ent.component + ":" + ent.name;
    debug_cout << "DEBUG in MonitoringAggregator::removeEntity : Removing entity " << idStr << std::endl;

    auto it = m_aggregations.find(idStr);
    if (it != m_aggregations.end()) {
      auto aggregation = (*it).second;
      // check whether the removed entity is one of the sources
      auto it2 = std::find(begin(aggregation.sources), end(aggregation.sources), ent);
      if (it2 != aggregation.sources.end()) {
        if (it2 == aggregation.sources.begin() && aggregation.sources.size() > 1) {
          // if removing the first source then we must preserve the aggregation in the next one
          aggregation.sources.at(1).mergeAndReset(ent);
          m_hub->removeEntity(aggregation.sources.front());
          m_hub->registerEntity(aggregation.sources.at(1));
        }
        aggregation.sources.erase(it2);

        // if the aggregation no longer has any sources then remove and deregister it
        if (aggregation.sources.empty()) {
          m_aggregations.erase(it);
        }
      }
    }
  }

  virtual ~MonitoringAggregator() {}

  void process()
  {
    for (auto agg : m_aggregations) {
      for (auto it = agg.second.sources.begin() + 1; it != agg.second.sources.end(); ++it) {
        agg.second.sources.front().mergeAndReset(*it);
      }
    }

    // Now check for incoming entities
    while (m_number_incoming_to_process > 0) {
      processNextIncomingEntity();
      --m_number_incoming_to_process;
    }
    m_number_incoming_to_process = m_incoming_entities.size();
  }

private:
  void processNextIncomingEntity()
  {
    auto ent = m_incoming_entities.front();

    auto idStr = ent.type + ":" + ent.component + ":" + ent.name;
    debug_cout << "DEBUG in MonitoringAggregator::registerEntity : Registering entity " << idStr << std::endl;

    auto it = m_aggregations.find(idStr);
    if (it != m_aggregations.end()) {
      auto aggregation = (*it).second;
      aggregation.sources.push_back(ent);
    }
    else {
      m_aggregations[idStr].sources.push_back(ent);
      m_hub->registerEntity(ent);
    }
    m_incoming_entities.pop();
  }

  std::queue<Entity> m_incoming_entities;
  unsigned int m_number_incoming_to_process {0};

  std::map<std::string, Aggregation> m_aggregations;

  Gaudi::Monitoring::Hub* m_hub = &Gaudi::svcLocator()->monitoringHub();
};
#endif
