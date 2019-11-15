#pragma once

#include "MonitorBase.h"

struct MetaMonitor : public MonitorBase {
  MetaMonitor(int timeStep = 30, int offset = 0) : MonitorBase("monitoring", timeStep, offset) { init(); };

  virtual ~MetaMonitor() = default;

  void fill(bool successful, uint monitoringLevel);

private:
  void init();
};
