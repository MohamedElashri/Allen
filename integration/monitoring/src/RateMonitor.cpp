/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "RateMonitor.h"
#include "HostBuffersManager.cuh"
#include "Logger.h"
#include "HltDecReport.cuh"

void RateMonitor::fill(unsigned i_buf, bool useWallTime)
{
  const auto* store = m_buffers_manager->get_persistent_store(i_buf);
  const auto [host_dec_reports_valid, host_dec_reports] = store->try_at<unsigned>("dec_reporter__host_dec_reports_t");
  const auto [host_number_of_active_lines_valid, host_number_of_active_lines] =
    store->try_at<unsigned>("gather_selections__host_number_of_active_lines_t");

  if (host_dec_reports_valid && host_number_of_active_lines_valid) {
    if (!m_histograms_initialized) {
      initialize_histograms(host_number_of_active_lines[0]);
    }

    unsigned time(0);

    if (!useWallTime) {
      warning_cout << "ODIN time histograms not avaiable yet" << std::endl;
      return;
    }
    else {
      time = getWallTimeBin();
    }

    const auto [nevt_valid, nevt] = store->try_at<unsigned>("initialize_number_of_events__host_number_of_events_t");
    for (unsigned ievt = 0; ievt < nevt[0]; ++ievt) {
      auto dec_reports = host_dec_reports.data() + ievt * (3 + host_number_of_active_lines[0]);

      bool pass(false);

      for (unsigned i_line = 0; i_line < host_number_of_active_lines[0]; ++i_line) {
        if (dec_reports[i_line] & HltDecReport::decisionMask) {
          m_histograms[LineRatesStart + i_line]->Fill(time, 1. / m_time_step);
          pass = true;
        }
      }

      if (pass) m_histograms[InclusiveRate]->Fill(time, 1. / m_time_step);
    }
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
