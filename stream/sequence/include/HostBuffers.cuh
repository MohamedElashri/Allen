/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <string>
#include <gsl/gsl>
#include <BackendCommon.h>
#include <AllenBuffer.cuh>
#include <MemoryManager.cuh>

struct HostBuffers {
private:
  // Use a custom memory manager for the host pinned memory used here
  Allen::Store::host_memory_manager_t m_mem_manager {"Persistent memory manager", 200 * 1000 * 1000, 32};

public:
  // Buffer for saving events passing Hlt1 selections
  Allen::host_buffer<bool> host_passing_event_list {m_mem_manager, "host_passing_event_list"};

  // Dec / sel reports
  Allen::host_buffer<unsigned> host_dec_reports {m_mem_manager, "host_dec_reports"};
  Allen::host_buffer<unsigned> host_sel_reports {m_mem_manager, "host_sel_reports"};
  Allen::host_buffer<unsigned> host_sel_report_offsets {m_mem_manager, "host_sel_report_offsets"};

  // Lumi
  // The size of LumiSummary events is defined in the header file
  // device/lumi/include/LumiCounterOffsets.h
  // and LumiSummary only be present for events that pass the ODINLumi line.
  // The lumi event rate is expected to be on average 1 per 1000,
  // but due to binomial fluctuations one might see a slice
  // with around 11-12 in a typical 24 hour period.
  // The size of lumi_summaries is expected to be much smaller than sel reports
  Allen::host_buffer<unsigned> host_lumi_summaries {m_mem_manager, "host_lumi_summaries"};
  Allen::host_buffer<unsigned> host_lumi_summary_offsets {m_mem_manager, "host_lumi_summary_offsets"};

  // Selections
  unsigned host_number_of_events = 0;
  unsigned host_number_of_selected_events = 0;
  std::string host_names_of_lines = "";
  unsigned host_number_of_lines = 0;
};
