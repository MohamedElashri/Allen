/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "RateMonitor.h"
#include "HostBuffers.cuh"
#include "HostBuffersManager.cuh"
#include "Logger.h"

#ifdef WITH_ROOT
void RateMonitor::fill(unsigned i_buf, bool useWallTime)
{
  HostBuffers* buf = m_buffers_manager->getBuffers(i_buf);

  unsigned time(0);

  if (!useWallTime) {
    warning_cout << "ODIN time histograms not avaiable yet" << std::endl;
    return;
  }
  else {
    time = getWallTimeBin();
  }

  unsigned nevt = buf->host_number_of_events;

  // TODO
  // for (unsigned ievt = 0; ievt < nevt; ++ievt) {
  //   auto dec_reports = buf->host_dec_reports + 2 + ievt * (2 + m_number_of_hlt1_lines);

  //   bool pass(false);

  //   for (unsigned i_line = 0; i_line < m_number_of_hlt1_lines; ++i_line) {
  //     if (dec_reports[i_line] & HltDecReport::decisionMask) {
  //       m_histograms[LineRatesStart + i_line]->Fill(time, 1. / m_time_step);
  //       pass = true;
  //     }
  //   }

  //  if (pass) m_histograms[InclusiveRate]->Fill(time, 1. / m_time_step);
  // }
}

void RateMonitor::init()
{
  // set number of bins such that histograms cover approximately 80 minutes
  unsigned nBins = 80 * 60 / m_time_step;
  double max = nBins * m_time_step;

  m_histograms.emplace(InclusiveRate, new TH1D("inclusiveRate", "", nBins, 0., max));
  for (unsigned i_line = 0; i_line < m_number_of_hlt1_lines; ++i_line) {
    TString name = "line";
    name += i_line;
    name += "Rate";
    m_histograms.emplace(LineRatesStart + i_line, new TH1D(name, "", nBins, 0., max));
  }

  for (auto& kv : m_histograms) {
    kv.second->SetDirectory(nullptr);
    kv.second->Sumw2();
  }
}
#else
void RateMonitor::fill(unsigned, bool) {}
void RateMonitor::init()
{
  _unused(m_buffers_manager);
  _unused(m_number_of_hlt1_lines);
}
#endif
