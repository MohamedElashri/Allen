#include "MetaMonitor.h"

#ifdef WITH_ROOT
void MetaMonitor::fill(bool successful, unsigned monitoringLevel)
{
  unsigned time = getWallTimeBin();

  if (successful) {
    m_histograms[MonitoringSuccess]->Fill(time);
  }
  else {
    m_histograms[MonitoringSkipped]->Fill(time);
  }

  switch (monitoringLevel) {
  case 0: m_histograms[MonitoringLevel0]->Fill(time); break;
  case 1: m_histograms[MonitoringLevel1]->Fill(time); break;
  case 2: m_histograms[MonitoringLevel2]->Fill(time); break;
  case 3: m_histograms[MonitoringLevel3]->Fill(time); break;
  case 4: m_histograms[MonitoringLevel4]->Fill(time); break;
  default: m_histograms[MonitoringLevel5P]->Fill(time); break;
  }
}

void MetaMonitor::fillSplit()
{
  unsigned time = getWallTimeBin();

  m_histograms[SplitSlices]->Fill(time);
}

void MetaMonitor::init()
{
  // set number of bins such that histograms cover approximately 80 minutes
  unsigned nBins = 80 * 60 / m_time_step;
  double max = nBins * m_time_step;

  m_histograms.emplace(MonitoringSuccess, new TH1D("monitoringSuccess", "", nBins, 0., max));
  m_histograms.emplace(MonitoringSkipped, new TH1D("monitoringSkipped", "", nBins, 0., max));
  m_histograms.emplace(MonitoringLevel0, new TH1D("monitoringLevel0", "", nBins, 0., max));
  m_histograms.emplace(MonitoringLevel1, new TH1D("monitoringLevel1", "", nBins, 0., max));
  m_histograms.emplace(MonitoringLevel2, new TH1D("monitoringLevel2", "", nBins, 0., max));
  m_histograms.emplace(MonitoringLevel3, new TH1D("monitoringLevel3", "", nBins, 0., max));
  m_histograms.emplace(MonitoringLevel4, new TH1D("monitoringLevel4", "", nBins, 0., max));
  m_histograms.emplace(MonitoringLevel5P, new TH1D("monitoringLevel5p", "", nBins, 0., max));
  m_histograms.emplace(SplitSlices, new TH1D("splitSlices", "", nBins, 0., max));

  for (auto kv : m_histograms) {
    kv.second->SetDirectory(nullptr);
  }
}
#else
void MetaMonitor::fill(bool, unsigned) {}
void MetaMonitor::fillSplit() {}
void MetaMonitor::init() {}
#endif
