/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "HostGlobalEventCut.h"

void host_global_event_cut::host_global_event_cut_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  const HostBuffers&) const
{
  const auto number_of_events =
    std::get<1>(runtime_options.event_interval) - std::get<0>(runtime_options.event_interval);

  set_size<host_number_of_selected_events_t>(arguments, 1);
  set_size<host_number_of_events_t>(arguments, 1);
  set_size<host_event_list_t>(arguments, number_of_events);
  set_size<dev_number_of_events_t>(arguments, 1);
  set_size<dev_event_list_t>(arguments, number_of_events);
}

void host_global_event_cut::host_global_event_cut_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers& host_buffers,
  cudaStream_t& stream,
  cudaEvent_t&) const
{
  const auto event_start = std::get<0>(runtime_options.event_interval);
  const auto event_end = std::get<1>(runtime_options.event_interval);
  const auto number_of_events = event_end - event_start;

  // Initialize number of events
  data<host_number_of_events_t>(arguments)[0] = number_of_events;
  copy<dev_number_of_events_t, host_number_of_events_t>(arguments, stream);

  // Initialize host event list
  for (unsigned i = 0; i < number_of_events; ++i) {
    data<host_event_list_t>(arguments)[i] = i;
  }

  // Do the host global event cut
  if (runtime_options.mep_layout) {
    host_function(host_global_event_cut_mep)(number_of_events, arguments);
  }
  else {
    host_function(host_global_event_cut)(number_of_events, arguments);
  }

  // Copy data to the device
  copy<dev_event_list_t, host_event_list_t>(arguments, stream);

  // Reduce the size of the event lists to the selected events
  reduce_size<host_event_list_t>(arguments, first<host_number_of_selected_events_t>(arguments));
  reduce_size<dev_event_list_t>(arguments, first<host_number_of_selected_events_t>(arguments));

  // TODO: Remove whenever the checker uses variables
  host_buffers.host_number_of_selected_events = first<host_number_of_selected_events_t>(arguments);
  for (unsigned i = 0; i < size<host_event_list_t>(arguments); ++i) {
    host_buffers.host_event_list[i] = event_start + data<host_event_list_t>(arguments)[i];
  }
}

void host_global_event_cut::host_global_event_cut(
  const unsigned number_of_events,
  host_global_event_cut::Parameters parameters)
{
  auto const ut_offsets = *parameters.ut_offsets;
  auto const scifi_offsets = *parameters.scifi_offsets;

  unsigned insert_index = 0;
  unsigned first_event = parameters.host_event_list[0];
  for (unsigned event_index = 0; event_index < number_of_events; ++event_index) {
    unsigned event_number = first_event + event_index;
    // Check SciFi clusters
    const SciFi::SciFiRawEvent scifi_event(parameters.scifi_banks[0].data() + scifi_offsets[event_number]);
    unsigned n_SciFi_clusters = 0;
    for (unsigned i = 0; i < scifi_event.number_of_raw_banks; ++i) {
      // get bank size in bytes, subtract four bytes for header word
      unsigned bank_size = scifi_event.raw_bank_offset[i + 1] - scifi_event.raw_bank_offset[i] - 4;
      n_SciFi_clusters += bank_size;
    }

    // Bank size is given in bytes. There are 2 bytes per cluster.
    // 4 bytes are removed for the header.
    // Note that this overestimates slightly the number of clusters
    // due to bank padding in 32b. For v5, it further overestimates the
    // number of clusters due to the merging of clusters.
    n_SciFi_clusters = (n_SciFi_clusters >> 1) - 2;

    // Check UT clusters
    const uint32_t ut_event_offset = ut_offsets[event_number];
    const UTRawEvent ut_event(parameters.ut_banks[0].data() + ut_event_offset);
    unsigned n_UT_clusters = 0;

    for (unsigned i = 0; i < ut_event.number_of_raw_banks; ++i) {
      const UTRawBank ut_bank = ut_event.getUTRawBank(i);
      n_UT_clusters += ut_bank.number_of_hits;
    }

    const auto num_combined_clusters = n_UT_clusters + n_SciFi_clusters;
    if (
      num_combined_clusters < parameters.max_scifi_ut_clusters &&
      num_combined_clusters > parameters.min_scifi_ut_clusters) {
      parameters.host_event_list[insert_index++] = event_number;
    }
  }

  parameters.host_number_of_selected_events[0] = insert_index;
}

void host_global_event_cut::host_global_event_cut_mep(
  const unsigned number_of_events,
  host_global_event_cut::Parameters parameters)
{
  auto const ut_offsets = *parameters.ut_offsets;
  auto const scifi_offsets = *parameters.scifi_offsets;

  unsigned insert_index = 0;
  for (unsigned event_number = 0; event_number < number_of_events; ++event_number) {
    // Check SciFi clusters

    auto const number_of_scifi_raw_banks = scifi_offsets[0];
    unsigned n_SciFi_clusters = 0;

    for (unsigned i = 0; i < number_of_scifi_raw_banks; ++i) {
      unsigned const offset_index = 2 + number_of_scifi_raw_banks * (1 + event_number);
      unsigned bank_size =
        scifi_offsets[offset_index + i + number_of_scifi_raw_banks] - scifi_offsets[offset_index + i];
      // std::cout << "scifi " << std::setw(4) << event_number << " " << std::setw(3) << i << " " << bank_size << "\n";
      n_SciFi_clusters += bank_size;
    }

    // Bank size is given in bytes. There are 2 bytes per cluster.
    // 4 bytes are removed for the header.
    // Note that this overestimates slightly the number of clusters
    // due to bank padding in 32b. For v5, it further overestimates the
    // number of clusters due to the merging of clusters.
    n_SciFi_clusters = (n_SciFi_clusters >> 1) - 2;

    // Check UT clusters
    auto const number_of_ut_raw_banks = ut_offsets[0];
    unsigned n_UT_clusters = 0;

    for (unsigned i = 0; i < number_of_ut_raw_banks; ++i) {
      auto sourceID = ut_offsets[2 + i];
      // We're on the host, so use the blocks directly
      auto block_offset = ut_offsets[2 + number_of_ut_raw_banks + i];
      auto const fragment_offset = ut_offsets[2 + number_of_ut_raw_banks * (1 + event_number) + i] - block_offset;
      const UTRawBank ut_bank {sourceID, parameters.ut_banks[i].data() + fragment_offset};
      n_UT_clusters += ut_bank.number_of_hits;
    }

    const auto num_combined_clusters = n_UT_clusters + n_SciFi_clusters;
    if (
      num_combined_clusters < parameters.max_scifi_ut_clusters &&
      num_combined_clusters > parameters.min_scifi_ut_clusters) {
      parameters.host_event_list[insert_index++] = event_number;
    }
  }

  parameters.host_number_of_events[0] = insert_index;
}
