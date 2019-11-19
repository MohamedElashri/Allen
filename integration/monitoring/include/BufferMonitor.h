#pragma once

#include "MonitorBase.h"

struct BufferMonitor : public MonitorBase {
  BufferMonitor(std::string name, int timeStep, int offset) : MonitorBase(name, timeStep, offset) {}

  virtual ~BufferMonitor() = default;

  virtual void fill(uint i_buf, bool useWallTime = true) = 0;
};
