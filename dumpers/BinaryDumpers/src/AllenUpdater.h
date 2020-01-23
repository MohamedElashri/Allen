/*****************************************************************************\
* (c) Copyright 2019 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the GNU General Public      *
* Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <GaudiKernel/Service.h>
#include <map>
#include <memory>
#include <string>

#include "Dumpers/IUpdater.h"

/** @class AllenUpdater AllenUpdater.h
 *  LHCb implementation of the Allen non-event data manager
 *
 *  @author Roel Aaij
 *  @date   2019-05-24
 */
class AllenUpdater final : public Service, public Allen::NonEventData::IUpdater {
public:
  AllenUpdater( std::string name, ISvcLocator* loc ) : Service{name, loc} {}

  /**
   * @brief      Update all registered non-event data by calling all
   *             registered Producer and Consumer
   *
   * @param      run number or event time
   *
   * @return     void
   */
  void update( unsigned long run ) override;

  /**
   * @brief      Register a consumer for that will consume binary non-event
   *             data; identified by string
   *
   * @param      identifier string
   * @param      the consumer
   *
   * @return     void
   */
  void registerConsumer( std::string const& id, std::unique_ptr<Allen::NonEventData::Consumer> c ) override;

  /**
   * @brief      Register a producer that will produce binary non-event
   *             data; identified by string
   *
   * @param      identifier string
   * @param      the producer
   *
   * @return     void
   */
  void registerProducer( std::string const& id, Allen::NonEventData::Producer p ) override;

private:
  std::map<std::string,
           std::tuple<Allen::NonEventData::Producer, std::vector<std::unique_ptr<Allen::NonEventData::Consumer>>>>
      m_pairs;
};
