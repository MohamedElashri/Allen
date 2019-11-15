#pragma once

#include "BufferMonitor.h"

struct HostBuffersManager;

struct RateMonitor : public BufferMonitor {
  RateMonitor(HostBuffersManager* buffers_manager, int timeStep = 30, int offset = 0) :
    BufferMonitor("hltRates", timeStep, offset), m_buffers_manager(buffers_manager)
  {
    init();
  };

  virtual ~RateMonitor() = default;

  void fill(uint i_buf, bool useWallTime = true) override;

private:
  void init();

  HostBuffersManager* m_buffers_manager;
};
