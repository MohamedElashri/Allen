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
#include "AllenROOTService.h"

DECLARE_COMPONENT(AllenROOTService)

AllenROOTService::AllenROOTService(std::string name, ISvcLocator* loc) : Service {name, loc} {}

StatusCode AllenROOTService::queryInterface(const InterfaceID& riid, void** ppv)
{
  if (AllenROOTService::interfaceID().versionMatch(riid)) {
    *ppv = this;
    addRef();
    return StatusCode::SUCCESS;
  }
  return Service::queryInterface(riid, ppv);
}

StatusCode AllenROOTService::initialize()
{
  return Service::initialize().andThen([&] { m_rootService = std::make_unique<ROOTService>(m_monitorFile.value()); });
}

/**
 * @brief      Get the Allen ROOTService service
 *
 * @return     ROOTService*
 */
ROOTService* AllenROOTService::rootService() { return m_rootService.get(); }
