#include "MetaMonitor.h"

#ifdef WITH_ROOT
void MetaMonitor::fill(bool successful, uint monitoringLevel)
{
  uint time = getWallTimeBin();

  if (successful) {
    m_histograms[MonHistType::MonitoringSuccess]->Fill(time);
  }
  else {
    m_histograms[MonHistType::MonitoringSkipped]->Fill(time);
  }

  switch (monitoringLevel) {
  case 0: m_histograms[MonHistType::MonitoringLevel0]->Fill(time); break;
  case 1: m_histograms[MonHistType::MonitoringLevel1]->Fill(time); break;
  case 2: m_histograms[MonHistType::MonitoringLevel2]->Fill(time); break;
  case 3: m_histograms[MonHistType::MonitoringLevel3]->Fill(time); break;
  case 4: m_histograms[MonHistType::MonitoringLevel4]->Fill(time); break;
  default: m_histograms[MonHistType::MonitoringLevel5P]->Fill(time); break;
  }
}

void MetaMonitor::fillSplit()
{
  uint time = getWallTimeBin();

  m_histograms[MonHistType::SplitSlices]->Fill(time);
}

void MetaMonitor::init()
{
  // set number of bins such that histograms cover approximately 80 minutes
  uint nBins = 80 * 60 / m_time_step;
  double max = nBins * m_time_step;

  m_histograms.emplace(MonHistType::MonitoringSuccess, new TH1D("monitoringSuccess", "", nBins, 0., max));
  m_histograms.emplace(MonHistType::MonitoringSkipped, new TH1D("monitoringSkipped", "", nBins, 0., max));
  m_histograms.emplace(MonHistType::MonitoringLevel0, new TH1D("monitoringLevel0", "", nBins, 0., max));
  m_histograms.emplace(MonHistType::MonitoringLevel1, new TH1D("monitoringLevel1", "", nBins, 0., max));
  m_histograms.emplace(MonHistType::MonitoringLevel2, new TH1D("monitoringLevel2", "", nBins, 0., max));
  m_histograms.emplace(MonHistType::MonitoringLevel3, new TH1D("monitoringLevel3", "", nBins, 0., max));
  m_histograms.emplace(MonHistType::MonitoringLevel4, new TH1D("monitoringLevel4", "", nBins, 0., max));
  m_histograms.emplace(MonHistType::MonitoringLevel5P, new TH1D("monitoringLevel5p", "", nBins, 0., max));
  m_histograms.emplace(MonHistType::SplitSlices, new TH1D("splitSlices", "", nBins, 0., max));

  for (auto kv : m_histograms) {
    kv.second->SetDirectory(nullptr);
  }
}
#else
void MetaMonitor::fill(bool, uint) {}
void MetaMonitor::fillSplit() {}
void MetaMonitor::init() {}
#endif
