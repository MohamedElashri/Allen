/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
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

  void fill(unsigned i_buf, bool useWallTime = true) override;

private:
  void init();

  void initialize_histograms(const unsigned host_number_of_active_lines);

  HostBuffersManager* m_buffers_manager;
  bool m_histograms_initialized = false;
  unsigned m_nBins;
  double m_max;
};
