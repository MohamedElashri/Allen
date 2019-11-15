#pragma once

#include "BufferMonitor.h"
#include "MetaMonitor.h"

#include <optional>
#include <queue>
#include <vector>

struct HostBuffersManager;

struct MonitorManager {
  MonitorManager(uint n_mon_thread, HostBuffersManager* buffers_manager, int time_step = 30, int offset = 0) :
    meta_mon(time_step, offset)
  {
    init(n_mon_thread, buffers_manager, time_step, offset);
  }

  void fill(uint i_mon, uint i_buf, bool useWallTime = true);
  void saveHistograms(std::string file_name);

  std::optional<size_t> getFreeMonitor();
  void freeMonitor(size_t i_mon);

private:
  void init(uint n_mon_thread, HostBuffersManager* buffers_manager, int time_step, int offset);

  std::vector<std::vector<BufferMonitor*>> m_monitors;

  std::queue<size_t> free_monitors;

  MetaMonitor meta_mon;
  uint count_processed {0}, count_skipped {0};
  uint monitoring_level {0};
  const uint max_monitoring_level {0};
};
