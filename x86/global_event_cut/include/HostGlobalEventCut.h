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
    PROPERTY(min_scifi_ut_clusters_t, uint, "min_scifi_ut_clusters", "minimum number of scifi + ut clusters")
    min_scifi_ut_clusters;
    PROPERTY(max_scifi_ut_clusters_t, uint, "max_scifi_ut_clusters", "maximum number of scifi + ut clusters")
    max_scifi_ut_clusters;
  };

  // Function
  void host_global_event_cut(
    BanksAndOffsets const& ut_raw,
    BanksAndOffsets const& scifi_raw,
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

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      const HostBuffers&) const
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
      const Constants&,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      const auto event_start = std::get<0>(runtime_options.event_interval);
      const auto event_end = std::get<1>(runtime_options.event_interval);
      const auto number_of_events = event_end - event_start;

      // Initialize host event list
      begin<host_total_number_of_events_t>(arguments)[0] = number_of_events;
      begin<host_number_of_selected_events_t>(arguments)[0] = number_of_events;
      for (uint i = 0; i < number_of_events; ++i) {
        begin<host_event_list_t>(arguments)[i] = event_start + i;
      }

      // Parameters for the function call
      const auto parameters = Parameters {begin<host_event_list_t>(arguments),
                                          begin<host_number_of_selected_events_t>(arguments),
                                          property<min_scifi_ut_clusters_t>(),
                                          property<max_scifi_ut_clusters_t>()};

      using function_t = decltype(host_function(host_global_event_cut));

      // Select the function to run, MEP or Allen layout
      function_t function = runtime_options.mep_layout ? function_t{host_global_event_cut_mep} : function_t{host_global_event_cut};

      // Run the function
      auto const slice = runtime_options.slice_index;
      function(runtime_options.input_provider->banks(BankTypes::UT, slice),
               runtime_options.input_provider->banks(BankTypes::FT, slice),
               number_of_events, parameters);

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
    Property<min_scifi_ut_clusters_t> m_min_scifi_ut_clusters {this, 0};
    Property<max_scifi_ut_clusters_t> m_max_scifi_ut_clusters {this, 9750};
  };
} // namespace host_global_event_cut
