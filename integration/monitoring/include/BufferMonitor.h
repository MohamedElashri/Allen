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
#pragma once

#include "MonitorBase.h"

struct BufferMonitor : public MonitorBase {
  BufferMonitor(MonitorManager* manager, std::string name, int timeStep, int offset) :
    MonitorBase(manager, name, timeStep, offset)
  {}

  virtual ~BufferMonitor() = default;

  virtual void fill(unsigned i_buf, bool useWallTime = true) = 0;
};
