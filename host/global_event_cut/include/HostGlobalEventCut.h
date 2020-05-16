#pragma once

#include "Common.h"
#include "SciFiRaw.cuh"
#include "UTRaw.cuh"
#include "HostAlgorithm.cuh"

namespace host_global_event_cut {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_ut_raw_banks_t, gsl::span<char const>), ut_banks),
    (HOST_INPUT(host_ut_raw_offsets_t, gsl::span<unsigned int const>), ut_offsets),
    (HOST_INPUT(host_scifi_raw_banks_t, gsl::span<char const>), scifi_banks),
    (HOST_INPUT(host_scifi_raw_offsets_t, gsl::span<unsigned int const>), scifi_offsets),
    (HOST_OUTPUT(host_total_number_of_events_t, uint), host_total_number_of_events),
    (HOST_OUTPUT(host_event_list_t, uint), host_event_list),
    (HOST_OUTPUT(host_number_of_selected_events_t, uint), host_number_of_selected_events),
    (DEVICE_OUTPUT(dev_event_list_t, uint), dev_event_list),
    (PROPERTY(min_scifi_ut_clusters_t, "min_scifi_ut_clusters", "minimum number of scifi + ut clusters", uint),
     min_scifi_ut_clusters),
    (PROPERTY(max_scifi_ut_clusters_t, "max_scifi_ut_clusters", "maximum number of scifi + ut clusters", uint),
     max_scifi_ut_clusters))

  // Function
  void host_global_event_cut(uint number_of_events, Parameters parameters);

  void host_global_event_cut_mep(const uint number_of_events, Parameters parameters);

  // Algorithm
  struct host_global_event_cut_t : public HostAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<min_scifi_ut_clusters_t> m_min_scifi_ut_clusters {this, 0};
    Property<max_scifi_ut_clusters_t> m_max_scifi_ut_clusters {this, 9750};
  };
} // namespace host_global_event_cut
