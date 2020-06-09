#pragma once

#include "BufferMonitor.h"

struct HostBuffersManager;

struct PVMonitor : public BufferMonitor {
  PVMonitor(HostBuffersManager* buffers_manager, int timeStep = 30, int offset = 0) :
    BufferMonitor("fittedPVs", timeStep, offset), m_buffers_manager(buffers_manager)
  {
    init();
  };

  virtual ~PVMonitor() = default;

  void fill(unsigned i_buf, bool useWallTime = true) override;

private:
  void init();

  HostBuffersManager* m_buffers_manager = nullptr;
};
