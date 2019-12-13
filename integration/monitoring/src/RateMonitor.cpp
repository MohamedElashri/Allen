#include "RateMonitor.h"
#include "HostBuffers.cuh"
#include "HostBuffersManager.cuh"
#include "Logger.h"

#include "HltDecReport.cuh"
#include "RawBanksDefinitions.cuh"

#ifdef WITH_ROOT
void RateMonitor::fill(uint i_buf, bool useWallTime)
{
  HostBuffers* buf = m_buffers_manager->getBuffers(i_buf);

  uint time(0);

  if (!useWallTime) {
    warning_cout << "ODIN time histograms not avaiable yet" << std::endl;
    return;
  }
  else {
    time = getWallTimeBin();
  }

  uint nevt = buf->host_number_of_selected_events[0];

  for (uint ievt = 0; ievt < nevt; ++ievt) {
    auto dec_reports = buf->host_dec_reports + 2 + ievt * (2 + Hlt1::End);

    bool pass_through_pass = (dec_reports[0] & HltDecReport::decisionMask);
    bool one_track_pass = (dec_reports[1] & HltDecReport::decisionMask);
    bool two_track_pass = (dec_reports[2] & HltDecReport::decisionMask);
    bool single_muon_pass = (dec_reports[3] & HltDecReport::decisionMask);
    bool disp_dimuon_pass = (dec_reports[4] & HltDecReport::decisionMask);
    bool high_mass_dimuon_pass = (dec_reports[5] & HltDecReport::decisionMask);

    if (pass_through_pass) m_histograms[MonHistType::PassThroughRate]->Fill(time, 1. / m_time_step);
    if (one_track_pass) m_histograms[MonHistType::OneTrackRate]->Fill(time, 1. / m_time_step);
    if (two_track_pass) m_histograms[MonHistType::TwoTrackRate]->Fill(time, 1. / m_time_step);
    if (single_muon_pass) m_histograms[MonHistType::SingleMuonRate]->Fill(time, 1. / m_time_step);
    if (disp_dimuon_pass) m_histograms[MonHistType::DispDimuonRate]->Fill(time, 1. / m_time_step);
    if (high_mass_dimuon_pass) m_histograms[MonHistType::HighMassDimuonRate]->Fill(time, 1. / m_time_step);
    if (one_track_pass || two_track_pass || single_muon_pass || disp_dimuon_pass || high_mass_dimuon_pass)
      m_histograms[MonHistType::InclusiveRate]->Fill(time, 1. / m_time_step);
  }
}

void RateMonitor::init()
{
  // set number of bins such that histograms cover approximately 80 minutes
  uint nBins = 80 * 60 / m_time_step;
  double max = nBins * m_time_step;

  m_histograms.emplace(MonHistType::PassThroughRate, new TH1D("passThroughRate", "", nBins, 0., max));
  m_histograms.emplace(MonHistType::OneTrackRate, new TH1D("oneTrackRate", "", nBins, 0., max));
  m_histograms.emplace(MonHistType::TwoTrackRate, new TH1D("twoTrackRate", "", nBins, 0., max));
  m_histograms.emplace(MonHistType::SingleMuonRate, new TH1D("singleMuonRate", "", nBins, 0., max));
  m_histograms.emplace(MonHistType::DispDimuonRate, new TH1D("dispDimuonRate", "", nBins, 0., max));
  m_histograms.emplace(MonHistType::HighMassDimuonRate, new TH1D("highMassDimuonRate", "", nBins, 0., max));
  m_histograms.emplace(MonHistType::InclusiveRate, new TH1D("inclusiveRate", "", nBins, 0., max));

  for (auto kv : m_histograms) {
    kv.second->SetDirectory(nullptr);
    kv.second->Sumw2();
  }
}
#else
void RateMonitor::fill(uint, bool) {}
void RateMonitor::init() {}
#endif
