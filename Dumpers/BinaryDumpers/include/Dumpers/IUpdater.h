/*****************************************************************************\
* (c) Copyright 2019 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include <functional>
#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "Identifiers.h"

namespace Allen {
  namespace NonEventData {

    struct Consumer {
      /**
       * @brief      Consume binary non-event data to copy to an accelerator
       *
       * @param      binary data to be consumed
       *
       * @return     void
       */
      virtual void consume(std::vector<char> const& data) = 0;
      virtual ~Consumer() = default;
    };

    /**
     * @brief      Producer type expected by IUpdater
     *
     */
    using Producer = std::function<std::optional<std::vector<char>>()>;

    /** @class IUpdater IUpdater.h Dumpers/IUpdater.h
     *  Interface - shared with Allen - to the manager of Producer and Consumer
     *  of binary non-event data.
     *
     *  @author Roel Aaij
     *  @date   2019-05-27
     */
    class IUpdater {
    public:
      virtual ~IUpdater() {}

      /**
       * @brief      Register a consumer for that will consume binary non-event
       *             data; identified by identifier type C
       *
       * @param      the consumer
       *
       * @return     void
       */
      template<typename C>
      void registerConsumer(std::unique_ptr<Consumer> c)
      {
        registerConsumer(C::id, std::move(c));
      }

      /**
       * @brief      Register a producer that will produce binary non-event
       *             data; identified by identifier type P
       *
       * @param      the producer
       *
       * @return     void
       */
      template<typename P>
      void registerProducer(Producer p)
      {
        registerProducer(P::id, std::move(p));
      }

      /**
       * @brief      Update all registered non-event data by calling all
       *             registered Producer and Consumer
       *
       * @param      run number or event time
       *
       * @return     void
       */
      virtual void update(unsigned long run) = 0;

      /**
       * @brief      Register a consumer for that will consume binary non-event
       *             data; identified by string
       *
       * @param      identifier string
       * @param      the consumer
       *
       * @return     void
       */
      virtual void registerConsumer(std::string const& id, std::unique_ptr<Consumer> c) = 0;

      /**
       * @brief      Register a producer that will produce binary non-event
       *             data; identified by string
       *
       * @param      identifier string
       * @param      the producer
       *
       * @return     void
       */
      virtual void registerProducer(std::string const& id, Producer p) = 0;
    };
  } // namespace NonEventData
} // namespace Allen
