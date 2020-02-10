#include "MonitorManager.h"

#include "RateMonitor.h"
#include "TrackMonitor.h"
#include "PVMonitor.h"
#include "SVMonitor.h"

#include "HostBuffersManager.cuh"
#include "Logger.h"

void MonitorManager::fill(uint i_mon, uint i_buf, bool useWallTime)
{
  if (i_mon >= m_monitors.size()) {
    warning_cout << "No monitors exist for thread " << i_mon << std::endl;
    return;
  }
  for (auto mon : m_monitors.at(i_mon)) {
    mon->fill(i_buf, useWallTime);
  }
}

void MonitorManager::saveHistograms(std::string file_name)
{
  meta_mon.saveHistograms(file_name, false);
  for (auto mons : m_monitors) {
    for (auto mon : mons) {
      mon->saveHistograms(file_name, true);
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
    meta_mon.fill(false, monitoring_level);
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
  meta_mon.fill(true, monitoring_level);
  free_monitors.push(i_mon);
}

void MonitorManager::init(
  uint n_mon_thread,
  HostBuffersManager* buffers_manager,
  uint number_of_hlt1_lines,
  int time_step,
  int offset)
{
  for (uint i = 0; i < n_mon_thread; ++i) {
    m_monitors.push_back(std::vector<BufferMonitor*>());
    m_monitors.back().push_back(new RateMonitor(buffers_manager, number_of_hlt1_lines, time_step, offset));
    m_monitors.back().push_back(new TrackMonitor(buffers_manager, time_step, offset));
    m_monitors.back().push_back(new PVMonitor(buffers_manager, time_step, offset));
    m_monitors.back().push_back(new SVMonitor(buffers_manager, time_step, offset));
    free_monitors.push(i);
  }
}
