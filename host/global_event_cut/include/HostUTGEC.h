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

namespace host_ut_gec {
  struct Parameters {
    HOST_INPUT(host_ut_raw_banks_t, gsl::span<char const>) ut_banks;
    HOST_INPUT(host_ut_raw_offsets_t, gsl::span<unsigned int const>) ut_offsets;
    HOST_INPUT(host_ut_raw_sizes_t, gsl::span<unsigned int const>) ut_sizes;
    HOST_INPUT(host_ut_raw_types_t, gsl::span<unsigned int const>) ut_types;
    HOST_INPUT(host_ut_raw_bank_version_t, int) ut_raw_bank_version;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_OUTPUT(host_output_event_list_t, unsigned) host_output_event_list;
    HOST_OUTPUT(host_number_of_selected_events_t, unsigned) host_number_of_selected_events;
    DEVICE_OUTPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    MASK_OUTPUT(dev_event_list_output_t) dev_output_event_list;
    PROPERTY(min_clusters_t, "min_clusters", "minimum number of UT clusters", unsigned)
    min_clusters;
    PROPERTY(max_clusters_t, "max_clusters", "maximum number of UT clusters", unsigned)
    max_clusters;
  };

  // Templated GEC on the MEP layout
  template<bool mep_layout = true>
  void host_ut_gec(host_ut_gec::Parameters parameters, unsigned const event_start)
  {
    auto const ut_offsets = *parameters.ut_offsets;
    auto const ut_sizes = *parameters.ut_sizes;
    auto const ut_types = *parameters.ut_types;
    auto const ut_raw_bank_version = *parameters.ut_raw_bank_version;

    unsigned size_of_list = 0;

    for (unsigned event_index = 0; event_index < parameters.host_number_of_events[0]; ++event_index) {
      unsigned event_number = event_start + event_index;

      // Check UT clusters
      unsigned n_clusters = 0;

      if constexpr (mep_layout) {
        auto const number_of_ut_raw_banks = ut_offsets[0];
        for (unsigned i = 0; i < number_of_ut_raw_banks; ++i) {
          auto sourceID = ut_offsets[2 + i];
          // We're on the host, so use the blocks directly
          auto block_offset = ut_offsets[2 + number_of_ut_raw_banks + i];
          auto const fragment_offset = ut_offsets[2 + number_of_ut_raw_banks * (1 + event_number) + i] - block_offset;
          char const* bank_data = parameters.ut_banks[i].data() + fragment_offset;
          if (MEP::bank_type(bank_data, ut_types.data(), event_number, i) != LHCb::RawBank::UT) continue;
          auto const bank_size = MEP::bank_size(bank_data, ut_sizes.data(), event_number, i);
          if (ut_raw_bank_version == 4)
            n_clusters += UTRawBank<4> {sourceID, bank_data, bank_size, Allen::LastBankType}.get_n_hits();
          else if (ut_raw_bank_version == 3 || ut_raw_bank_version == -1)
            n_clusters += UTRawBank<3> {sourceID, bank_data, bank_size, Allen::LastBankType}.get_n_hits();
          else
            throw std::runtime_error("Unknown UT raw bank version " + std::to_string(ut_raw_bank_version));
        }
      }
      else {
        const UTRawEvent<false> ut_event(
          parameters.ut_banks[0].data(), ut_offsets.data(), ut_sizes.data(), event_number);

        for (unsigned i = 0; i < ut_event.number_of_raw_banks(); ++i) {
          if (Allen::bank_type(ut_types.data(), event_number, i) != LHCb::RawBank::UT) continue;
          if (ut_raw_bank_version == 4)
            n_clusters += ut_event.raw_bank<4>(i).get_n_hits();
          else if (ut_raw_bank_version == 3)
            n_clusters += ut_event.raw_bank<3>(i).get_n_hits();
          else
            throw std::runtime_error("Unknown UT raw bank version " + std::to_string(ut_raw_bank_version));
        }
      }

      if (n_clusters <= parameters.max_clusters && n_clusters >= parameters.min_clusters) {
        parameters.host_output_event_list[size_of_list++] = event_index;
      }
    }
    parameters.host_number_of_selected_events[0] = size_of_list;
  }

  // Algorithm
  struct host_ut_gec_t : public HostAlgorithm, Parameters {
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
    Property<min_clusters_t> m_min_clusters {this, 0};
    Property<max_clusters_t> m_max_clusters {this, 9750};
  };
} // namespace host_ut_gec
