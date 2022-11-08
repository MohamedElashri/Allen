/***************************************************************************** \
 * (c) Copyright 2000-2018 CERN for the benefit of the LHCb Collaboration      *
 *                                                                             *
 * This software is distributed under the terms of the GNU General Public      *
 * Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
 *                                                                             *
 * In applying this licence, CERN does not waive the privileges and immunities *
 * granted to it by virtue of its status as an Intergovernmental Organization  *
 * or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <map>
#include <memory>
#include <string>
#include <mutex>

#include <GaudiKernel/Service.h>
#include <ROOTService.h>

/** @class AllenROOTService AllenROOTService.h
 *  LHCb implementation of the Allen non-event data manager
 *
 *  @author Roel Aaij
 *  @date   2019-05-24
 */
class AllenROOTService final : public Service {
public:
  /// Retrieve interface ID
  static const InterfaceID& interfaceID()
  {
    // Declaration of the interface ID.
    static const InterfaceID iid("AllenROOTService", 0, 0);
    return iid;
  }

  /// Query interfaces of Interface
  StatusCode queryInterface(const InterfaceID& riid, void** ppv) override;

  AllenROOTService(std::string name, ISvcLocator* loc);

  StatusCode initialize() override;

  /**
   * @brief      Get the Allen ROOTService service
   *
   * @return     ROOTService*
   */
  ROOTService* rootService();

private:
  Gaudi::Property<std::string> m_monitorFile {this, "MonitorFile", "allen_monitor.root"};

  std::unique_ptr<ROOTService> m_rootService {};
};
