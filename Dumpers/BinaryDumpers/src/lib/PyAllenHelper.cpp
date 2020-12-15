/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <Dumpers/IUpdater.h>
#include <GaudiKernel/Service.h>

Allen::NonEventData::IUpdater* cast_updater(IService* updater_svc)
{
  return dynamic_cast<Allen::NonEventData::IUpdater*>(updater_svc);
}
