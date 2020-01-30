#include "TrackMonitor.h"
#include "HostBuffers.cuh"
#include "HostBuffersManager.cuh"
#include "Logger.h"

#include "HltDecReport.cuh"
#include "RawBanksDefinitions.cuh"
#include "ParKalmanDefinitions.cuh"
#include "LineInfo.cuh"

#include <cmath>

#ifdef WITH_ROOT
void TrackMonitor::fill(uint i_buf, bool)
{
  HostBuffers* buf = m_buffers_manager->getBuffers(i_buf);

  uint nevt = buf->host_number_of_selected_events[0];
  uint* trk_offsets = buf->host_atomics_scifi + nevt;

  for (uint ievt = 0; ievt < nevt; ++ievt) {
    int ntrk = buf->host_atomics_scifi[ievt];
    uint trk_offset = trk_offsets[ievt];

    for (int itrk = 0; itrk < ntrk; ++itrk) {
      const auto& track = buf->host_kf_tracks[trk_offset + itrk];

      m_histograms[KalmanTrackP]->Fill(track.p());
      m_histograms[KalmanTrackPt]->Fill(track.pt());
      m_histograms[KalmanTrackIPChi2]->Fill(log(track.ipChi2));
    }
  }
}

void TrackMonitor::init()
{
  uint nBins = 1000;

  m_histograms.emplace(KalmanTrackP, new TH1D("trackP", "", nBins, 0., 1e6));
  m_histograms.emplace(KalmanTrackPt, new TH1D("trackPt", "", nBins, 0., 2e4));
  m_histograms.emplace(KalmanTrackIPChi2, new TH1D("trackLogIPChi2", "", nBins, -10., 10.));

  for (auto kv : m_histograms) {
    kv.second->SetDirectory(nullptr);
    kv.second->Sumw2();
  }
}
#else
void TrackMonitor::fill(uint, bool) {}
void TrackMonitor::init() {}
#endif
