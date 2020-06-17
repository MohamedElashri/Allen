#pragma once

#include "BufferMonitor.h"

struct HostBuffersManager;

struct RateMonitor : public BufferMonitor {
  RateMonitor(HostBuffersManager* buffers_manager, unsigned number_of_hlt1_lines, int timeStep = 30, int offset = 0) :
    BufferMonitor("hltRates", timeStep, offset), m_buffers_manager(buffers_manager),
    m_number_of_hlt1_lines(number_of_hlt1_lines)
  {
    init();
  };

  virtual ~RateMonitor() = default;

  void fill(unsigned i_buf, bool useWallTime = true) override;

private:
  void init();

  HostBuffersManager* m_buffers_manager;
  const unsigned m_number_of_hlt1_lines;
};
