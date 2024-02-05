/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <ZeroMQ/IZeroMQSvc.h>
#ifndef STANDALONE
#ifdef DEBUG
#undef DEBUG
#endif
#include <GaudiKernel/Bootstrap.h>
#include <GaudiKernel/IProperty.h>
#include <GaudiKernel/IAppMgrUI.h>
#include <GaudiKernel/IStateful.h>
#include <GaudiKernel/ISvcLocator.h>
#include <GaudiKernel/SmartIF.h>
#endif

IZeroMQSvc* makeZmqSvc()
{
#ifdef STANDALONE
  static std::unique_ptr<IZeroMQSvc> svc {};
  if (!svc) {
    svc.reset(new IZeroMQSvc {});
  }
  return svc.get();
#else
  SmartIF<IStateful> app = Gaudi::createApplicationMgr();
  auto prop = app.as<IProperty>();
  bool sc = prop->setProperty("ExtSvc", "[\"ZeroMQSvc\"]").isSuccess();
  sc &= prop->setProperty("JobOptionsType", "\"NONE\"");
  sc &= app->configure();
  sc &= app->initialize();
  sc &= app->start();
  if (sc) {
    SmartIF<ISvcLocator> sloc = app.as<ISvcLocator>();
    auto zmqSvc = sloc->service<IZeroMQSvc>("ZeroMQSvc");
    return zmqSvc.get();
  }
  else {
    return nullptr;
  }
#endif
}
