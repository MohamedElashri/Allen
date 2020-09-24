/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "MonitorBase.h"

struct BufferMonitor : public MonitorBase {
  BufferMonitor(std::string name, int timeStep, int offset) : MonitorBase(name, timeStep, offset) {}

  virtual ~BufferMonitor() = default;

  virtual void fill(unsigned i_buf, bool useWallTime = true) = 0;
};
