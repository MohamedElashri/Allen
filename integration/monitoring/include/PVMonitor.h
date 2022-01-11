/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "BufferMonitor.h"

struct HostBuffersManager;

struct PVMonitor : public BufferMonitor {
#ifdef WITH_ROOT
  PVMonitor(MonitorManager* manager, HostBuffersManager* buffers_manager, int timeStep = 30, int offset = 0) :
    BufferMonitor(manager, "fittedPVs", timeStep, offset), m_buffers_manager(buffers_manager)
  {
    init();
  };
#else
  PVMonitor(MonitorManager* manager, HostBuffersManager*, int timeStep = 30, int offset = 0) :
    BufferMonitor(manager, "fittedPVs", timeStep, offset)
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
