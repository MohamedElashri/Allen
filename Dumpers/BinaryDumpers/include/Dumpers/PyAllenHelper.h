/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <GaudiKernel/IService.h>
#include <Dumpers/IUpdater.h>
#include <Allen/InputProvider.h>

/**
 * @brief      Helper function to cast the LHCb-implementation of the Allen
 *             non-event data manager to its shared interface
 *
 * @param      The Allen non-event data manager as an IService
 *
 * @return     The Allen non-event data manager as an IUpdater
 */
template<typename TO>
struct cast_service {
  TO* operator()(IService* svc) { return dynamic_cast<TO*>(svc); }
};

// template cast_service<Allen::NonEventData::IUpdater>;
// template cast_service<IInputProvider>(IService* svc);
