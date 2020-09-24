/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "MonitorBase.h"

struct MetaMonitor : public MonitorBase {
  MetaMonitor(int timeStep = 30, int offset = 0) : MonitorBase("monitoring", timeStep, offset) { init(); };

  virtual ~MetaMonitor() = default;

  void fill(bool successful, unsigned monitoringLevel);
  void fillSplit();

private:
  void init();
};
