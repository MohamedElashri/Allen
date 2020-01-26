#pragma once

#include "Common.h"
#include "SciFiRaw.cuh"
#include "UTRaw.cuh"
#include "HostAlgorithm.cuh"

namespace host_global_event_cut {
  struct Parameters {
    HOST_OUTPUT(host_total_number_of_events_t, uint);
    HOST_OUTPUT(host_event_list_t, uint) host_event_list;
    HOST_OUTPUT(host_number_of_selected_events_t, uint) host_number_of_selected_events;
    DEVICE_OUTPUT(dev_event_list_t, uint);
    PROPERTY(min_scifi_ut_clusters_t, uint, "min_scifi_ut_clusters", "minimum number of scifi + ut clusters", 0)
    min_scifi_ut_clusters;
    PROPERTY(max_scifi_ut_clusters_t, uint, "max_scifi_ut_clusters", "maximum number of scifi + ut clusters", 9750)
    max_scifi_ut_clusters;
  };

  // Function
  void host_global_event_cut(
    const char* ut_raw_input,
    const uint* ut_raw_input_offsets,
    const char* scifi_raw_input,
    const uint* scifi_raw_input_offsets,
    uint number_of_events,
    Parameters parameters);

  void host_global_event_cut_mep(
    BanksAndOffsets const& ut_raw,
    BanksAndOffsets const& scifi_raw,
    const uint number_of_events,
    Parameters parameters);

  // Algorithm
  template<typename T, char... S>
  struct host_global_event_cut_t : public HostAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(host_function(host_global_event_cut)) function {host_global_event_cut};
    decltype(host_function(host_global_event_cut_mep)) function_mep {host_global_event_cut_mep};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      const auto event_start = std::get<0>(runtime_options.event_interval);
      const auto event_end = std::get<1>(runtime_options.event_interval);

      set_size<host_total_number_of_events_t>(arguments, 1);
      set_size<host_number_of_selected_events_t>(arguments, 1);
      set_size<host_event_list_t>(arguments, event_end - event_start);
      set_size<dev_event_list_t>(arguments, event_end - event_start);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      const auto event_start = std::get<0>(runtime_options.event_interval);
      const auto event_end = std::get<1>(runtime_options.event_interval);
      const auto number_of_events = event_end - event_start;

      // Initialize host event list
      begin<host_total_number_of_events_t>(arguments)[0] = number_of_events;
      begin<host_number_of_selected_events_t>(arguments)[0] = number_of_events;
      for (uint i = 0; i < number_of_events; ++i) {
        begin<host_event_list_t>(arguments)[i] = i;
      }

      // Parameters for the function call
      const auto parameters = Parameters {begin<host_event_list_t>(arguments),
                                          begin<host_number_of_selected_events_t>(arguments),
                                          property<min_scifi_ut_clusters_t>(),
                                          property<max_scifi_ut_clusters_t>()};

      // Runtime selector based on layout of input data
      if (runtime_options.mep_layout) {
        function_mep(runtime_options.host_ut_events, runtime_options.host_scifi_events, number_of_events, parameters);
      }
      else {
        function(
          std::get<0>(runtime_options.host_ut_events)[0].begin(),
          std::get<2>(runtime_options.host_ut_events).begin(),
          std::get<0>(runtime_options.host_scifi_events)[0].begin(),
          std::get<2>(runtime_options.host_scifi_events).begin(),
          number_of_events,
          parameters);
      }

      cudaCheck(cudaMemcpyAsync(
        begin<dev_event_list_t>(arguments),
        begin<host_event_list_t>(arguments),
        size<dev_event_list_t>(arguments),
        cudaMemcpyHostToDevice,
        cuda_stream));

      // TODO: Remove whenever the checker uses variables
      host_buffers.host_number_of_selected_events[0] = value<host_number_of_selected_events_t>(arguments);
      for (uint i = 0; i < number_of_events; ++i) {
        host_buffers.host_event_list[i] = begin<host_event_list_t>(arguments)[i];
      }
    }

  private:
    Property<min_scifi_ut_clusters_t> m_min_scifi_ut_clusters {this};
    Property<max_scifi_ut_clusters_t> m_max_scifi_ut_clusters {this};
  };
} // namespace host_global_event_cut