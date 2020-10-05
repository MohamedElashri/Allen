/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "BufferMonitor.h"
#include "MetaMonitor.h"

#include <optional>
#include <queue>
#include <vector>

struct HostBuffersManager;

struct MonitorManager {
  MonitorManager(
    unsigned n_mon_thread,
    HostBuffersManager* buffers_manager,
    int time_step = 30,
    int offset = 0) :
    meta_mon(time_step, offset)
  {
    init(n_mon_thread, buffers_manager, time_step, offset);
  }

  void fill(unsigned i_mon, unsigned i_buf, bool useWallTime = true);
  void fillSplit() { meta_mon.fillSplit(); }
  void saveHistograms(std::string file_name);

  std::optional<size_t> getFreeMonitor();
  void freeMonitor(size_t i_mon);

private:
  void init(
    unsigned n_mon_thread,
    HostBuffersManager* buffers_manager,
    int time_step,
    int offset);

  std::vector<std::vector<BufferMonitor*>> m_monitors;

  std::queue<size_t> free_monitors;

  MetaMonitor meta_mon;
  unsigned count_processed {0}, count_skipped {0};
  unsigned monitoring_level {0};
  const unsigned max_monitoring_level {0};
};
