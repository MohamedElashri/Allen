#include "CpuGlobalEventCut.h"

void cpu_global_event_cut::cpu_global_event_cut(
  const char* ut_raw_input,
  const uint* ut_raw_input_offsets,
  const char* scifi_raw_input,
  const uint* scifi_raw_input_offsets,
  uint* number_of_selected_events,
  uint* event_list,
  uint number_of_events)
{
  uint insert_index = 0;
  for (uint event_number = 0; event_number < number_of_events; ++event_number) {
    // Check SciFi clusters
    const SciFi::SciFiRawEvent scifi_event(scifi_raw_input + scifi_raw_input_offsets[event_number]);
    uint n_SciFi_clusters = 0;

    for (uint i = 0; i < scifi_event.number_of_raw_banks; ++i) {
      // get bank size in bytes, subtract four bytes for header word
      uint bank_size = scifi_event.raw_bank_offset[i + 1] - scifi_event.raw_bank_offset[i] - 4;
      n_SciFi_clusters += bank_size;
    }

    // Bank size is given in bytes. There are 2 bytes per cluster.
    // 4 bytes are removed for the header.
    // Note that this overestimates slightly the number of clusters
    // due to bank padding in 32b. For v5, it further overestimates the
    // number of clusters due to the merging of clusters.
    n_SciFi_clusters = (n_SciFi_clusters >> 1) - 2;

    // Check UT clusters
    const uint32_t ut_event_offset = ut_raw_input_offsets[event_number];
    const UTRawEvent ut_event(ut_raw_input + ut_event_offset);
    uint n_UT_clusters = 0;

    for (uint i = 0; i < ut_event.number_of_raw_banks; ++i) {
      const UTRawBank ut_bank = ut_event.getUTRawBank(i);
      n_UT_clusters += ut_bank.number_of_hits;
    }

    const auto num_combined_clusters = n_UT_clusters + n_SciFi_clusters;
    if (num_combined_clusters < max_scifi_ut_clusters && num_combined_clusters > min_scifi_ut_clusters) {
      event_list[insert_index++] = event_number;
    }
  }

  number_of_selected_events[0] = insert_index;
}
