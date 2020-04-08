#include "TrackMonitor.h"
#include "HostBuffers.cuh"
#include "HostBuffersManager.cuh"
#include "Logger.h"

#include "ParKalmanDefinitions.cuh"

#include <cmath>

#ifdef WITH_ROOT
void TrackMonitor::fill(uint i_buf, bool)
{
  HostBuffers* buf = m_buffers_manager->getBuffers(i_buf);

  uint nevt = buf->host_number_of_selected_events[0];

  for (uint ievt = 0; ievt < nevt; ++ievt) {
    int trk_offset = buf->host_atomics_scifi[ievt];
    uint ntrk = buf->host_atomics_scifi[ievt + 1] - trk_offset;

    m_histograms[KalmanTrackN]->Fill(ntrk);

    for (uint itrk = 0; itrk < ntrk; ++itrk) {
      const auto& track = buf->host_kf_tracks[trk_offset + itrk];

      m_histograms[KalmanTrackP]->Fill(track.p());
      m_histograms[KalmanTrackPt]->Fill(track.pt());
      m_histograms[KalmanTrackEta]->Fill(track.eta());
      m_histograms[KalmanTrackIPChi2]->Fill(log(track.ipChi2));
    }
  }
}

void TrackMonitor::init()
{
  uint nBins = 1000;

  m_histograms.emplace(KalmanTrackN, new TH1D("Ntracks", "", 200, 0., 200.));
  m_histograms.emplace(KalmanTrackP, new TH1D("trackP", "", nBins, 0., 1e6));
  m_histograms.emplace(KalmanTrackPt, new TH1D("trackPt", "", nBins, 0., 2e4));
  m_histograms.emplace(KalmanTrackEta, new TH1D("trackEta", "", nBins, 0., 7.));
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
