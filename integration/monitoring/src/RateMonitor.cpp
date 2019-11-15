#include "RateMonitor.h"
#include "HostBuffers.cuh"
#include "HostBuffersManager.cuh"
#include "Logger.h"

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
  int* trk_offsets = buf->host_atomics_scifi + nevt;
  uint* sv_offsets = buf->host_sv_offsets;

  for (uint ievt = 0; ievt < nevt; ++ievt) {
    int ntrk = buf->host_atomics_scifi[ievt];
    int nsv = buf->host_sv_offsets[ievt + 1] - buf->host_sv_offsets[ievt];

    uint trk_offset = trk_offsets[ievt];
    uint sv_offset = sv_offsets[ievt];

    bool one_track_pass(false);
    bool two_track_pass(false);
    bool single_muon_pass(false);
    bool disp_dimuon_pass(false);
    bool high_mass_dimuon_pass(false);

    for (int itrk = 0; itrk < ntrk; ++itrk) {
      if (buf->host_one_track_decisions[itrk + trk_offset]) one_track_pass = true;
      if (buf->host_single_muon_decisions[itrk + trk_offset]) single_muon_pass = true;
    }
    for (int isv = 0; isv < nsv; ++isv) {
      if (buf->host_two_track_decisions[isv + sv_offset]) two_track_pass = true;
      if (buf->host_disp_dimuon_decisions[isv + sv_offset]) disp_dimuon_pass = true;
      if (buf->host_high_mass_dimuon_decisions[isv + sv_offset]) high_mass_dimuon_pass = true;
    }

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
