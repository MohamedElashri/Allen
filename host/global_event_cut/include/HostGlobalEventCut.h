/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <Event/RawBank.h>

#include "Common.h"
#include "SciFiRaw.cuh"
#include "UTRaw.cuh"
#include "AlgorithmTypes.cuh"
#include <gsl/span>

namespace host_global_event_cut {
  struct Parameters {
    HOST_INPUT(host_ut_raw_banks_t, gsl::span<char const>) ut_banks;
    HOST_INPUT(host_ut_raw_offsets_t, gsl::span<unsigned int const>) ut_offsets;
    HOST_INPUT(host_ut_raw_sizes_t, gsl::span<unsigned int const>) ut_sizes;
    HOST_INPUT(host_ut_raw_types_t, gsl::span<unsigned int const>) ut_types;
    HOST_INPUT(host_ut_raw_bank_version_t, int) ut_raw_bank_version;
    HOST_INPUT(host_scifi_raw_banks_t, gsl::span<char const>) scifi_banks;
    HOST_INPUT(host_scifi_raw_offsets_t, gsl::span<unsigned int const>) scifi_offsets;
    HOST_INPUT(host_scifi_raw_sizes_t, gsl::span<unsigned int const>) scifi_sizes;
    HOST_INPUT(host_scifi_raw_types_t, gsl::span<unsigned int const>) scifi_types;
    HOST_OUTPUT(host_event_list_output_t, unsigned) host_event_list;
    HOST_OUTPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_OUTPUT(host_number_of_selected_events_t, unsigned) host_number_of_selected_events;
    DEVICE_OUTPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_OUTPUT(dev_event_list_output_t) dev_event_list;
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
    auto const ut_sizes = *parameters.ut_sizes;
    auto const ut_types = *parameters.ut_types;
    auto const ut_raw_bank_version = *parameters.ut_raw_bank_version;
    auto const scifi_offsets = *parameters.scifi_offsets;
    auto const scifi_sizes = *parameters.scifi_sizes;
    auto const scifi_types = *parameters.scifi_types;

    unsigned size_of_list = 0;
    for (unsigned event_index = 0; event_index < number_of_events; ++event_index) {
      unsigned event_number = event_index;

      // Check SciFi clusters
      unsigned n_SciFi_clusters = 0;

      const auto scifi_event = SciFi::RawEvent<mep_layout> {
        parameters.scifi_banks[0].data(), scifi_offsets.data(), scifi_sizes.data(), scifi_types.data(), event_number};
      for (unsigned i = 0; i < scifi_event.number_of_raw_banks(); ++i) {
        if (scifi_event.bank_type(i) == LHCb::RawBank::FTCluster) {
          n_SciFi_clusters += scifi_event.bank_size(i);
        }
      }

      // Bank size is given in bytes. There are 2 bytes per cluster.
      // 4 bytes are removed for the header.
      // Note that this overestimates slightly the number of clusters
      // due to bank padding in 32b. For v5/v6, it further overestimates the
      // number of clusters due to the merging of clusters.
      n_SciFi_clusters = (n_SciFi_clusters / 2) - 2;

      // Check UT clusters
      unsigned n_UT_clusters = 0;

      if constexpr (mep_layout) {
        auto const number_of_ut_raw_banks = ut_offsets[0];
        for (unsigned i = 0; i < number_of_ut_raw_banks; ++i) {
          auto sourceID = ut_offsets[2 + i];
          // We're on the host, so use the blocks directly
          auto block_offset = ut_offsets[2 + number_of_ut_raw_banks + i];
          auto const fragment_offset = ut_offsets[2 + number_of_ut_raw_banks * (1 + event_number) + i] - block_offset;
          char const* bank_data = parameters.ut_banks[i].data() + fragment_offset;
          if (MEP::bank_type(bank_data, ut_types.data(), event_number, i) != LHCb::RawBank::UT)
            continue;
          auto const bank_size = MEP::bank_size(bank_data, ut_sizes.data(), event_number, i);
          if (ut_raw_bank_version == 4)
            n_UT_clusters += UTRawBank<4> {sourceID, bank_data, bank_size, Allen::LastBankType}.get_n_hits();
          else if (ut_raw_bank_version == 3 || ut_raw_bank_version == -1)
            n_UT_clusters += UTRawBank<3> {sourceID, bank_data, bank_size, Allen::LastBankType}.get_n_hits();
          else
            throw std::runtime_error("Unknown UT raw bank version " + std::to_string(ut_raw_bank_version));
        }
      }
      else {
        const UTRawEvent<false> ut_event(
          parameters.ut_banks[0].data(), ut_offsets.data(), ut_sizes.data(), event_number);

        for (unsigned i = 0; i < ut_event.number_of_raw_banks(); ++i) {
          if (Allen::bank_type(ut_types.data(), event_number, i) != LHCb::RawBank::UT)
            continue;
          if (ut_raw_bank_version == 4)
            n_UT_clusters += ut_event.raw_bank<4>(i).get_n_hits();
          else if (ut_raw_bank_version == 3 || ut_raw_bank_version == -1)
            n_UT_clusters += ut_event.raw_bank<3>(i).get_n_hits();
          else
            throw std::runtime_error("Unknown UT raw bank version " + std::to_string(ut_raw_bank_version));
        }
      }

      const auto num_combined_clusters = n_UT_clusters + n_SciFi_clusters;
      if (
        num_combined_clusters <= parameters.max_scifi_ut_clusters &&
        num_combined_clusters >= parameters.min_scifi_ut_clusters) {
        parameters.host_event_list[size_of_list++] = event_number;
      }
    }

    parameters.host_number_of_selected_events[0] = size_of_list;
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
