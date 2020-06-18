#pragma once

#include "BufferMonitor.h"

struct HostBuffersManager;

struct PVMonitor : public BufferMonitor {
#ifdef WITH_ROOT
  PVMonitor(HostBuffersManager* buffers_manager, int timeStep = 30, int offset = 0) :
    BufferMonitor("fittedPVs", timeStep, offset), m_buffers_manager(buffers_manager)
  {
    init();
  };
#else
  PVMonitor(HostBuffersManager*, int timeStep = 30, int offset = 0) :
    BufferMonitor("fittedPVs", timeStep, offset)
  {
    init();
  };
#endif

  virtual ~PVMonitor() = default;

  void fill(unsigned i_buf, bool useWallTime = true) override;

private:
  void init();

#ifdef WITH_ROOT
  HostBuffersManager* m_buffers_manager = nullptr;
#endif
};
