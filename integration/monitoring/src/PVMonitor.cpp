/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "PVMonitor.h"
#include "HostBuffers.cuh"
#include "HostBuffersManager.cuh"
#include "Logger.h"

#include "PV_Definitions.cuh"

#include <cmath>

#ifdef WITH_ROOT
void PVMonitor::fill(unsigned i_buf, bool)
{
  HostBuffers* buf = m_buffers_manager->getBuffers(i_buf);

  unsigned nevt = buf->host_number_of_selected_events[0];
  int pv_offset(0);

  for (unsigned ievt = 0; ievt < nevt; ++ievt) {
    unsigned npv = buf->host_number_of_multivertex[ievt];

    m_histograms[PrimaryVertexN]->Fill(npv);

    for (unsigned ipv = 0; ipv < npv; ++ipv) {
      const auto& pv = buf->host_reconstructed_multi_pvs[pv_offset + ipv];

      m_histograms[PrimaryVertexX]->Fill(pv.position.x);
      m_histograms[PrimaryVertexY]->Fill(pv.position.y);
      m_histograms[PrimaryVertexZ]->Fill(pv.position.z);
    }
    pv_offset += npv;
  }
}

void PVMonitor::init()
{
  unsigned nBins = 1000;

  m_histograms.emplace(PrimaryVertexN, new TH1D("NPVs", "", 50, 0., 50.));
  m_histograms.emplace(PrimaryVertexX, new TH1D("PVX", "", nBins, -200., 200.));
  m_histograms.emplace(PrimaryVertexY, new TH1D("PVY", "", nBins, -200., 200.));
  m_histograms.emplace(PrimaryVertexZ, new TH1D("PVZ", "", nBins, -500., 1000.));

  for (auto& kv : m_histograms) {
    kv.second->SetDirectory(nullptr);
    kv.second->Sumw2();
  }
}
#else
void PVMonitor::fill(unsigned, bool) {}
void PVMonitor::init() {}
#endif
