#pragma once

#include <deque>
#include <map>
#include <string>

#include "ROOTHeaders.h"

struct MonitorBase {
  enum class MonHistType {
    MonitoringSuccess,
    MonitoringSkipped,
    MonitoringLevel0,
    MonitoringLevel1,
    MonitoringLevel2,
    MonitoringLevel3,
    MonitoringLevel4,
    MonitoringLevel5P,
    OneTrackRate,
    TwoTrackRate,
    SingleMuonRate,
    DispDimuonRate,
    HighMassDimuonRate,
    InclusiveRate
  };

  MonitorBase(std::string name, int timeStep, int offset) : m_name(name), m_time_step(timeStep), m_offset(offset) {};

  virtual ~MonitorBase() = default;

  virtual void saveHistograms(std::string file_name, bool append) const;

protected:
  uint getWallTimeBin();

  std::string m_name;

#ifdef WITH_ROOT
  std::map<MonHistType, TH1*> m_histograms;
#endif

  uint m_time_step;
  uint m_offset;
};
