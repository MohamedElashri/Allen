/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <Dumpers/IUpdater.h>
#include <GaudiKernel/Service.h>

/**
 * @brief      Helper function to cast the LHCb-implementation of the Allen
 *             non-event data manager to its shared interface
 *
 * @param      The Allen non-event data manager as an IService
 *
 * @return     The Allen non-event data manager as an IUpdater
 */
Allen::NonEventData::IUpdater* cast_updater(IService* updater_svc);
