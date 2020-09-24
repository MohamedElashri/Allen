/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <deque>
#include <map>
#include <string>
#include <memory>

#include "ROOTHeaders.h"

struct MonitorBase {
  enum MonHistType {
    MonitoringSuccess = 0,
    MonitoringSkipped,
    SplitSlices,
    MonitoringLevel0,
    MonitoringLevel1,
    MonitoringLevel2,
    MonitoringLevel3,
    MonitoringLevel4,
    MonitoringLevel5P,
    InclusiveRate = 100,
    LineRatesStart = 101,
    LineRatesLast = 199,
    KalmanTrackN = 200,
    KalmanTrackP,
    KalmanTrackPt,
    KalmanTrackEta,
    KalmanTrackIPChi2,
    PrimaryVertexN = 300,
    PrimaryVertexX,
    PrimaryVertexY,
    PrimaryVertexZ,
    SecondaryVertexN = 400,
    SecondaryVertexX,
    SecondaryVertexY,
    SecondaryVertexZ,
    SecondaryVertexPt,
    SecondaryVertexEta,
    SecondaryVertexMinPt,
    SecondaryVertexMinIPChi2,
    SecondaryVertexSumPt,
    SecondaryVertexMDiMu,
    SecondaryVertexMCor,
  };

  MonitorBase(std::string name, int timeStep, int offset) : m_name(name), m_time_step(timeStep), m_offset(offset) {};

  virtual ~MonitorBase() = default;

  virtual void saveHistograms(std::string file_name, bool append) const;

protected:
  unsigned getWallTimeBin();

  std::string m_name;

#ifdef WITH_ROOT
  std::map<unsigned, std::unique_ptr<TH1>> m_histograms;
#endif

  unsigned m_time_step{};
  unsigned m_offset{};
};
