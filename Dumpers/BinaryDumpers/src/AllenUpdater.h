/*****************************************************************************\
* (c) Copyright 2019 CERN for the benefit of the LHCb Collaboration           *
\*****************************************************************************/
#pragma once

#include <map>
#include <memory>
#include <string>
#include <mutex>

#include <GaudiKernel/Service.h>
#include <Gaudi/Interfaces/IQueueingEventProcessor.h>

#include <Event/ODIN.h>

#include <Dumpers/IUpdater.h>

#include <tbb/task_arena.h>

/** @class AllenUpdater AllenUpdater.h
 *  LHCb implementation of the Allen non-event data manager
 *
 *  @author Roel Aaij
 *  @date   2019-05-24
 */
class AllenUpdater final : public Service, public Allen::NonEventData::IUpdater {
public:
  /// Retrieve interface ID
  static const InterfaceID& interfaceID()
  {
    // Declaration of the interface ID.
    static const InterfaceID iid("AllenUpdater", 0, 0);
    return iid;
  }

  /// Query interfaces of Interface
  StatusCode queryInterface(const InterfaceID& riid, void** ppv) override;

  AllenUpdater(std::string name, ISvcLocator* loc) : Service {name, loc} {}

  StatusCode initialize() override;

  StatusCode start() override;

  StatusCode stop() override;

  /**
   * @brief      Update all registered non-event data by calling all
   *             registered Producer and Consumer
   *
   * @param      run number or event time
   *
   * @return     void
   */
  void update(gsl::span<unsigned const> odin) override;

  /**
   * @brief      Register a consumer for that will consume binary non-event
   *             data; identified by string
   *
   * @param      identifier string
   * @param      the consumer
   *
   * @return     void
   */
  void registerConsumer(std::string const& id, std::unique_ptr<Allen::NonEventData::Consumer> c) override;

  /**
   * @brief      Register a producer that will produce binary non-event
   *             data; identified by string
   *
   * @param      identifier string
   * @param      the producer
   *
   * @return     void
   */
  void registerProducer(std::string const& id, Allen::NonEventData::Producer p) override;

  LHCb::ODIN odin() const { return m_odin ? *m_odin : LHCb::ODIN {}; }

private:
  Gaudi::Property<bool> m_triggerEventLoop {this, "TriggerEventLoop", false};

  std::map<
    std::string,
    std::tuple<Allen::NonEventData::Producer, std::vector<std::unique_ptr<Allen::NonEventData::Consumer>>>>
    m_pairs;

  std::unique_ptr<tbb::task_arena> m_taskArena;

  SmartIF<Gaudi::Interfaces::IQueueingEventProcessor> m_evtProc;

  std::mutex m_odinMutex;
  std::optional<LHCb::ODIN> m_odin;
};
