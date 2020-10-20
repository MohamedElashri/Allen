/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <functional>
#include <optional>
#include <vector>
#include <string>
#include <memory>

#include <Dumpers/Identifiers.h>

namespace Allen {
  namespace NonEventData {

    struct Consumer {
      virtual void consume(std::vector<char> const& data) = 0;
      virtual ~Consumer() = default;
    };

    using Producer = std::function<std::optional<std::vector<char>>()>;

    class IUpdater {
    public:
      virtual ~IUpdater() {}

      template<typename C>
      void registerConsumer(std::unique_ptr<Consumer> c)
      {
        registerConsumer(C::id, std::move(c));
      }

      template<typename P>
      void registerProducer(Producer p)
      {
        registerProducer(P::id, std::move(p));
      }

      virtual void update(unsigned long run) = 0;

      virtual void registerConsumer(std::string const& id, std::unique_ptr<Consumer> c) = 0;

      virtual void registerProducer(std::string const& id, Producer p) = 0;
    };
  } // namespace NonEventData
} // namespace Allen
