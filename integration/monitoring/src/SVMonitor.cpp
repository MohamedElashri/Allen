/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "SVMonitor.h"
#include "HostBuffers.cuh"
#include "HostBuffersManager.cuh"
#include "Logger.h"

#include "VertexDefinitions.cuh"

#include <cmath>

#ifdef WITH_ROOT
void SVMonitor::fill(unsigned i_buf, bool)
{
  HostBuffers* buf = m_buffers_manager->getBuffers(i_buf);

  unsigned nevt = buf->host_number_of_events[0];

  for (unsigned ievt = 0; ievt < nevt; ++ievt) {
    int sv_offset = buf->host_sv_offsets[ievt];
    unsigned nsv = buf->host_sv_offsets[ievt + 1] - sv_offset;

    m_histograms[SecondaryVertexN]->Fill(nsv);

    for (unsigned isv = 0; isv < nsv; ++isv) {
      const auto& sv = buf->host_secondary_vertices[sv_offset + isv];

      m_histograms[SecondaryVertexX]->Fill(sv.x);
      m_histograms[SecondaryVertexY]->Fill(sv.y);
      m_histograms[SecondaryVertexZ]->Fill(sv.z);
      m_histograms[SecondaryVertexPt]->Fill(sv.pt());
      m_histograms[SecondaryVertexEta]->Fill(sv.eta);
      m_histograms[SecondaryVertexMinPt]->Fill(sv.minpt);
      m_histograms[SecondaryVertexMinIPChi2]->Fill(sv.minipchi2);
      m_histograms[SecondaryVertexSumPt]->Fill(sv.sumpt);
      m_histograms[SecondaryVertexMDiMu]->Fill(sv.mdimu);
      m_histograms[SecondaryVertexMCor]->Fill(sv.mcor);
    }
  }
}

void SVMonitor::init()
{
  unsigned nBins = 1000;

  m_histograms.emplace(SecondaryVertexN, new TH1D("NSVs", "", 200, 0., 200.));
  m_histograms.emplace(SecondaryVertexX, new TH1D("SVX", "", nBins, -200., 200.));
  m_histograms.emplace(SecondaryVertexY, new TH1D("SVY", "", nBins, -200., 200.));
  m_histograms.emplace(SecondaryVertexZ, new TH1D("SVZ", "", nBins, -500., 1000.));
  m_histograms.emplace(SecondaryVertexPt, new TH1D("SVPt", "", nBins, 0., 2e4));
  m_histograms.emplace(SecondaryVertexEta, new TH1D("SVEta", "", nBins, 0., 7.));
  m_histograms.emplace(SecondaryVertexMinPt, new TH1D("SVMinPt", "", nBins, 0., 2e4));
  m_histograms.emplace(SecondaryVertexMinIPChi2, new TH1D("SVMinIPChi2", "", nBins, 0., 100.));
  m_histograms.emplace(SecondaryVertexSumPt, new TH1D("SVSumPt", "", nBins, 0., 2e4));
  m_histograms.emplace(SecondaryVertexMDiMu, new TH1D("SVMdimu", "", nBins, 0., 1e5));
  m_histograms.emplace(SecondaryVertexMCor, new TH1D("SVMcor", "", nBins, 0., 1e5));

  for (auto& kv : m_histograms) {
    kv.second->SetDirectory(nullptr);
    kv.second->Sumw2();
  }
}
#else
void SVMonitor::fill(unsigned, bool) {}
void SVMonitor::init() {}
#endif
