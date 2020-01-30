#pragma once

#include <deque>
#include <map>
#include <string>

#include "ROOTHeaders.h"

struct MonitorBase {
  enum MonHistType {
    MonitoringSuccess = 0,
    MonitoringSkipped = 1,
    SplitSlices = 2,
    MonitoringLevel0 = 3,
    MonitoringLevel1 = 4,
    MonitoringLevel2 = 5,
    MonitoringLevel3 = 6,
    MonitoringLevel4 = 7,
    MonitoringLevel5P = 8,
    InclusiveRate = 100,
    LineRatesStart = 101,
    LineRatesLast = 199,
    KalmanTrackN = 200,
    KalmanTrackP = 201,
    KalmanTrackPt = 202,
    KalmanTrackEta = 203,
    KalmanTrackIPChi2 = 204
  };

  MonitorBase(std::string name, int timeStep, int offset) : m_name(name), m_time_step(timeStep), m_offset(offset) {};

  virtual ~MonitorBase() = default;

  virtual void saveHistograms(std::string file_name, bool append) const;

protected:
  uint getWallTimeBin();

  std::string m_name;

#ifdef WITH_ROOT
  std::map<uint, TH1*> m_histograms;
#endif

  uint m_time_step;
  uint m_offset;
};
