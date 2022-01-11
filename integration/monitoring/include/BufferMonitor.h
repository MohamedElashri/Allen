/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "MonitorBase.h"

struct BufferMonitor : public MonitorBase {
  BufferMonitor(MonitorManager* manager, std::string name, int timeStep, int offset) :
    MonitorBase(manager, name, timeStep, offset)
  {}

  virtual ~BufferMonitor() = default;

  virtual void fill(unsigned i_buf, bool useWallTime = true) = 0;
};
