#pragma once

#include "BufferMonitor.h"

struct HostBuffersManager;

struct RateMonitor : public BufferMonitor {
  RateMonitor(HostBuffersManager* buffers_manager, uint number_of_hlt1_lines, int timeStep = 30, int offset = 0) :
    BufferMonitor("hltRates", timeStep, offset), m_buffers_manager(buffers_manager),
    m_number_of_hlt1_lines(number_of_hlt1_lines)
  {
    init();
  };

  virtual ~RateMonitor() = default;

  void fill(uint i_buf, bool useWallTime = true) override;

private:
  void init();

  [[maybe_unused]] HostBuffersManager* m_buffers_manager;
  [[maybe_unused]] const uint m_number_of_hlt1_lines;
};
