/*****************************************************************************\
* (c) Copyright 2000-2019 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <GaudiKernel/IService.h>
#include <Dumpers/IUpdater.h>
#include <Allen/InputProvider.h>

#include <zmq/zmq.hpp>

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

template<typename T>
struct shared_wrap {
  std::shared_ptr<T> operator()(T* t)
  {
    return {t, [](T*) {}};
  }
};

uintptr_t czmq_context(zmq::context_t& ctx) {
  return reinterpret_cast<uintptr_t>(ctx.operator void*());
}

// template cast_service<Allen::NonEventData::IUpdater>;
// template cast_service<IInputProvider>(IService* svc);
