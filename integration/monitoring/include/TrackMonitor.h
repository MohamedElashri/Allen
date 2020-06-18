#pragma once

#include "BufferMonitor.h"

struct HostBuffersManager;

struct TrackMonitor : public BufferMonitor {
  TrackMonitor(HostBuffersManager* buffers_manager, int timeStep = 30, int offset = 0) :
    BufferMonitor("kalmanTracks", timeStep, offset), m_buffers_manager(buffers_manager)
  {
    init();
  };

  virtual ~TrackMonitor() = default;

  void fill(unsigned i_buf, bool useWallTime = true) override;

private:
  void init();

#ifdef WITH_ROOT
  HostBuffersManager* m_buffers_manager;
#endif
};
