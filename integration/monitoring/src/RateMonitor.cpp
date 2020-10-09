/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "RateMonitor.h"
#include "HostBuffers.cuh"
#include "HostBuffersManager.cuh"
#include "Logger.h"
#include "HltDecReport.cuh"

#ifdef WITH_ROOT
void RateMonitor::fill(unsigned i_buf, bool useWallTime)
{
  HostBuffers* buf = m_buffers_manager->getBuffers(i_buf);

  if (!m_histograms_initialized) {
    initialize_histograms(buf->host_number_of_lines);
  }

  unsigned time(0);

  if (!useWallTime) {
    warning_cout << "ODIN time histograms not avaiable yet" << std::endl;
    return;
  }
  else {
    time = getWallTimeBin();
  }

  unsigned nevt = buf->host_number_of_events;

  for (unsigned ievt = 0; ievt < nevt; ++ievt) {
    auto dec_reports = buf->host_dec_reports.data() + 2 + ievt * (2 + buf->host_number_of_lines);

    bool pass(false);

    for (unsigned i_line = 0; i_line < buf->host_number_of_lines; ++i_line) {
      if (dec_reports[i_line] & HltDecReport::decisionMask) {
        m_histograms[LineRatesStart + i_line]->Fill(time, 1. / m_time_step);
        pass = true;
      }
    }

    if (pass) m_histograms[InclusiveRate]->Fill(time, 1. / m_time_step);
  }
}

void RateMonitor::init()
{
  // set number of bins such that histograms cover approximately 80 minutes
  m_nBins = 80 * 60 / m_time_step;
  m_max = m_nBins * m_time_step;
  m_histograms.emplace(InclusiveRate, new TH1D("inclusiveRate", "", m_nBins, 0., m_max));

  // The initialization of histograms is delayed until the number of active lines is known
  m_histograms_initialized = false;
}

void RateMonitor::initialize_histograms(const unsigned host_number_of_active_lines)
{
  for (unsigned i_line = 0; i_line < host_number_of_active_lines; ++i_line) {
    TString name = "line";
    name += i_line;
    name += "Rate";
    m_histograms.emplace(LineRatesStart + i_line, new TH1D(name, "", m_nBins, 0., m_max));
  }

  for (auto& kv : m_histograms) {
    kv.second->SetDirectory(nullptr);
    kv.second->Sumw2();
  }

  m_histograms_initialized = true;
}

#else
void RateMonitor::fill(unsigned, bool) {}

void RateMonitor::init() {
  _unused(m_buffers_manager);
  _unused(m_histograms_initialized);
  _unused(m_nBins);
  _unused(m_max);
}

void RateMonitor::initialize_histograms(const unsigned) {}
#endif
