/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "Common.h"
#include "SciFiRaw.cuh"
#include "UTRaw.cuh"
#include "HostAlgorithm.cuh"

namespace host_global_event_cut {
  struct Parameters {
    HOST_INPUT(host_ut_raw_banks_t, gsl::span<char const>) ut_banks;
    HOST_INPUT(host_ut_raw_offsets_t, gsl::span<unsigned int const>) ut_offsets;
    HOST_INPUT(host_scifi_raw_banks_t, gsl::span<char const>) scifi_banks;
    HOST_INPUT(host_scifi_raw_offsets_t, gsl::span<unsigned int const>) scifi_offsets;
    HOST_OUTPUT(host_event_list_t, unsigned) host_event_list;
    HOST_OUTPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_OUTPUT(host_number_of_selected_events_t, unsigned) host_number_of_selected_events;
    DEVICE_OUTPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_OUTPUT(dev_event_list_t, unsigned) dev_event_list;
    PROPERTY(min_scifi_ut_clusters_t, "min_scifi_ut_clusters", "minimum number of scifi + ut clusters", unsigned)
    min_scifi_ut_clusters;
    PROPERTY(max_scifi_ut_clusters_t, "max_scifi_ut_clusters", "maximum number of scifi + ut clusters", unsigned)
    max_scifi_ut_clusters;
  };

  // Templated GEC on the MEP layout
  template<bool mep_layout = true>
  void host_global_event_cut(host_global_event_cut::Parameters parameters)
  {
    const auto number_of_events = parameters.host_number_of_events[0];

    auto const ut_offsets = *parameters.ut_offsets;
    auto const scifi_offsets = *parameters.scifi_offsets;

    unsigned insert_index = 0;
    unsigned first_event = parameters.host_event_list[0];
    for (unsigned event_index = 0; event_index < number_of_events; ++event_index) {
      unsigned event_number = first_event + event_index;

      // Check SciFi clusters
      unsigned n_SciFi_clusters = 0;

      if constexpr (mep_layout) {
        auto const number_of_scifi_raw_banks = scifi_offsets[0];
        for (unsigned i = 0; i < number_of_scifi_raw_banks; ++i) {
          unsigned const offset_index = 2 + number_of_scifi_raw_banks * (1 + event_number);
          unsigned bank_size =
            scifi_offsets[offset_index + i + number_of_scifi_raw_banks] - scifi_offsets[offset_index + i];
          n_SciFi_clusters += bank_size;
        }
      }
      else {
        const SciFi::SciFiRawEvent scifi_event(parameters.scifi_banks[0].data() + scifi_offsets[event_number]);
        for (unsigned i = 0; i < scifi_event.number_of_raw_banks; ++i) {
          // get bank size in bytes, subtract four bytes for header word
          unsigned bank_size = scifi_event.raw_bank_offset[i + 1] - scifi_event.raw_bank_offset[i] - 4;
          n_SciFi_clusters += bank_size;
        }
      }

      // Bank size is given in bytes. There are 2 bytes per cluster.
      // 4 bytes are removed for the header.
      // Note that this overestimates slightly the number of clusters
      // due to bank padding in 32b. For v5, it further overestimates the
      // number of clusters due to the merging of clusters.
      n_SciFi_clusters = (n_SciFi_clusters >> 1) - 2;

      // Check UT clusters
      unsigned n_UT_clusters = 0;

      if constexpr (mep_layout) {
        auto const number_of_ut_raw_banks = ut_offsets[0];
        for (unsigned i = 0; i < number_of_ut_raw_banks; ++i) {
          auto sourceID = ut_offsets[2 + i];
          // We're on the host, so use the blocks directly
          auto block_offset = ut_offsets[2 + number_of_ut_raw_banks + i];
          auto const fragment_offset = ut_offsets[2 + number_of_ut_raw_banks * (1 + event_number) + i] - block_offset;
          const UTRawBank ut_bank {sourceID, parameters.ut_banks[i].data() + fragment_offset};
          n_UT_clusters += ut_bank.number_of_hits;
        }
      }
      else {
        const uint32_t ut_event_offset = ut_offsets[event_number];
        const UTRawEvent ut_event(parameters.ut_banks[0].data() + ut_event_offset);

        for (unsigned i = 0; i < ut_event.number_of_raw_banks; ++i) {
          const UTRawBank ut_bank = ut_event.getUTRawBank(i);
          n_UT_clusters += ut_bank.number_of_hits;
        }
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
      const Allen::Context& context) const;

  private:
    Property<min_scifi_ut_clusters_t> m_min_scifi_ut_clusters {this, 0};
    Property<max_scifi_ut_clusters_t> m_max_scifi_ut_clusters {this, 9750};
  };
} // namespace host_global_event_cut
