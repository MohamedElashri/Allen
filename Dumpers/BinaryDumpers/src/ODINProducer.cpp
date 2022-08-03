/*****************************************************************************\
   * (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration      *
   *                                                                             *
   * This software is distributed under the terms of the GNU General Public      *
   * Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   *
   *                                                                             *
   * In applying this licence, CERN does not waive the privileges and immunities *
   * granted to it by virtue of its status as an Intergovernmental Organization  *
   * or submit itself to any jurisdiction.                                       *
\*****************************************************************************/

#include "LHCbAlgs/Producer.h"
#include "Event/ODIN.h"

#include "AllenUpdater.h"

namespace Allen {

  class ODINProducer : public LHCb::Algorithm::Producer<LHCb::ODIN()> {
  public:
    ODINProducer( const std::string& name, ISvcLocator* pSvcLocator )
      : LHCb::Algorithm::Producer<LHCb::ODIN()>( name, pSvcLocator, KeyValue{"ODIN", LHCb::ODINLocation::Default} ) {}

    StatusCode initialize() override;

    LHCb::ODIN operator()() const override;

  private:
    SmartIF<AllenUpdater> m_updater;
  };
}

DECLARE_COMPONENT_WITH_ID(Allen::ODINProducer, "AllenODINProducer")

StatusCode Allen::ODINProducer::initialize()
{
  return Producer::initialize().andThen( [&] {
    m_updater = service<AllenUpdater>("AllenUpdater");
    return m_updater.isValid() ? StatusCode::SUCCESS : StatusCode::FAILURE;
  });
}

LHCb::ODIN Allen::ODINProducer::operator()() const
{
  auto odin = m_updater->odin();
  if (odin.runNumber() == 0) {
    throw GaudiException{name(), "Failed to obtain valid ODIN from AllenUpdater", StatusCode::FAILURE};
  } else {
    return odin;
  }
}
