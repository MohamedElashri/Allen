/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "MonitorManager.h"

#include "RateMonitor.h"
#include "TrackMonitor.h"
#include "PVMonitor.h"

#include "HostBuffersManager.cuh"
#include "Logger.h"

MonitorManager::MonitorManager(
  unsigned n_mon_thread,
  HostBuffersManager* buffers_manager,
  [[maybe_unused]] ROOTService* rsvc,
  int time_step,
  int offset)
{
#ifdef WITH_ROOT
  m_rsvc = rsvc;
  m_dir = rsvc->handle("Monitors").directory();
#endif

  meta_mon = std::make_unique<MetaMonitor>(this, time_step, offset);
  for (unsigned i = 0; i < n_mon_thread; ++i) {
    m_monitors.push_back(std::vector<std::unique_ptr<BufferMonitor>>());
    m_monitors.back().emplace_back(new RateMonitor(this, buffers_manager, time_step, offset));
    m_monitors.back().emplace_back(new TrackMonitor(this, buffers_manager, time_step, offset));
    m_monitors.back().emplace_back(new PVMonitor(this, buffers_manager, time_step, offset));
    free_monitors.push(i);
  }
}

void MonitorManager::fill(unsigned i_mon, unsigned i_buf, bool useWallTime)
{
  if (i_mon >= m_monitors.size()) {
    warning_cout << "No monitors exist for thread " << i_mon << std::endl;
    return;
  }
  for (auto& mon : m_monitors.at(i_mon)) {
    mon->fill(i_buf, useWallTime);
  }
}

void MonitorManager::saveHistograms()
{
#ifdef WITH_ROOT
  [[maybe_unused]] auto handle = m_rsvc->handle("Monitors");
#endif
  meta_mon->saveHistograms();
  for (auto& mons : m_monitors) {
    for (auto& mon : mons) {
      mon->saveHistograms();
    }
  }
}

std::optional<size_t> MonitorManager::getFreeMonitor()
{
  if (free_monitors.empty()) {
    ++count_skipped;
    if (count_skipped > 2) {
      if (monitoring_level < max_monitoring_level) {
        ++monitoring_level;
        info_cout << "Reducing monitoring rate" << std::endl;
      }
      count_skipped = 0;
      count_processed = 0;
    }
    meta_mon->fill(false, monitoring_level);
    return std::nullopt;
  }
  auto ret = std::optional<size_t>(free_monitors.front());
  free_monitors.pop();
  return ret;
}

void MonitorManager::freeMonitor(size_t i_mon)
{
  ++count_processed;
  if (count_processed > 10) {
    if (monitoring_level > 0) {
      --monitoring_level;
      info_cout << "Increasing monitoring rate" << std::endl;
    }
    count_skipped = 0;
    count_processed = 0;
  }
  meta_mon->fill(true, monitoring_level);
  free_monitors.push(i_mon);
}
