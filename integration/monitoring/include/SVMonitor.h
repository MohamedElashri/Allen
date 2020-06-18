#pragma once

#include "BufferMonitor.h"

struct HostBuffersManager;

struct SVMonitor : public BufferMonitor {
  SVMonitor(HostBuffersManager* buffers_manager, int timeStep = 30, int offset = 0) :
    BufferMonitor("fittedSVs", timeStep, offset), m_buffers_manager(buffers_manager)
  {
    init();
  };

  virtual ~SVMonitor() = default;

  void fill(unsigned i_buf, bool useWallTime = true) override;

private:
  void init();

#ifdef WITH_ROOT
  HostBuffersManager* m_buffers_manager;
#endif
};
