/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "BufferMonitor.h"
#include "MetaMonitor.h"
#include <ROOTHeaders.h>
#include <ROOTService.h>

#include <optional>
#include <queue>
#include <vector>

struct HostBuffersManager;

struct MonitorManager {
  MonitorManager(
    unsigned n_mon_thread,
    HostBuffersManager* buffers_manager,
    ROOTService* rsvc,
    int time_step = 30,
    int offset = 0);

  void fill(unsigned i_mon, unsigned i_buf, bool useWallTime = true);
  void fillSplit() { meta_mon->fillSplit(); }
  void saveHistograms();

  std::optional<size_t> getFreeMonitor();
  void freeMonitor(size_t i_mon);

#ifdef WITH_ROOT
  TDirectory* directory() { return m_dir; }
#endif

private:
  ROOTService* m_rsvc = nullptr;
  std::vector<std::vector<std::unique_ptr<BufferMonitor>>> m_monitors;

  std::queue<size_t> free_monitors;

#ifdef WITH_ROOT
  TDirectory* m_dir = nullptr;
#endif

  std::unique_ptr<MetaMonitor> meta_mon;
  unsigned count_processed {0}, count_skipped {0};
  unsigned monitoring_level {0};
  const unsigned max_monitoring_level {0};
};
