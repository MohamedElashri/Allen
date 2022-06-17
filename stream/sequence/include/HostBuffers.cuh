/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <string>
#include <gsl/gsl>
#include <BackendCommon.h>
#include <AllenBuffer.cuh>
#include <MemoryManager.cuh>

// Forward declarations
namespace PV {
  class Vertex;
}
namespace ParKalmanFilter {
  struct FittedTrack;
}

struct HostBuffers {
private:
  // Use a custom memory manager for the host pinned memory used here
  Allen::Store::host_memory_manager_t m_mem_manager {"Persistent memory manager", 200 * 1000 * 1000, 32};

public:
  // Buffer for saving events passing Hlt1 selections
  Allen::host_buffer<bool> host_passing_event_list {m_mem_manager, "host_passing_event_list"};

  // Monitoring
  Allen::host_buffer<PV::Vertex> host_reconstructed_multi_pvs {m_mem_manager, "host_reconstructed_multi_pvs"};
  Allen::host_buffer<unsigned> host_number_of_multivertex {m_mem_manager, "host_number_of_multivertex"};
  Allen::host_buffer<unsigned> host_atomics_scifi {m_mem_manager, "host_atomics_scifi"};
  Allen::host_buffer<ParKalmanFilter::FittedTrack> host_kf_tracks {m_mem_manager, "host_kf_tracks"};
  
  // Dec / sel reports
  Allen::host_buffer<unsigned> host_dec_reports {m_mem_manager, "host_dec_reports"};
  Allen::host_buffer<unsigned> host_sel_reports {m_mem_manager, "host_sel_reports"};
  Allen::host_buffer<unsigned> host_sel_report_offsets {m_mem_manager, "host_sel_report_offsets"};

  // Selections
  unsigned host_number_of_events = 0;
  unsigned host_number_of_selected_events = 0;
  std::string host_names_of_lines = "";
  unsigned host_number_of_lines = 0;
};
