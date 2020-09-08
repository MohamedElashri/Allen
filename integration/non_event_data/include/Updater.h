/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <string>
#include <map>
#include <memory>

#include "Dumpers/IUpdater.h"

namespace Allen {
  namespace NonEventData {

    class Updater final : public IUpdater {
    public:
      Updater() = delete;
      Updater(std::map<std::string, std::string> const& options);
      virtual ~Updater() = default;

      void update(unsigned long run) override;

      void registerConsumer(std::string const& id, std::unique_ptr<NonEventData::Consumer> c) override;

      void registerProducer(std::string const& id, NonEventData::Producer p) override;

    private:
      std::map<std::string, std::tuple<NonEventData::Producer, std::vector<std::unique_ptr<NonEventData::Consumer>>>>
        m_pairs;
    };
  } // namespace NonEventData
} // namespace Allen

Allen::NonEventData::IUpdater* make_updater(std::map<std::string, std::string>& options);
