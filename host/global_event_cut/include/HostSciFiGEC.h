/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <Event/RawBank.h>

#include "Common.h"
#include "SciFiRaw.cuh"
#include "AlgorithmTypes.cuh"
#include <gsl/span>

namespace host_scifi_gec {
  struct Parameters {
    HOST_INPUT(host_scifi_raw_banks_t, gsl::span<char const>) scifi_banks;
    HOST_INPUT(host_scifi_raw_offsets_t, gsl::span<unsigned int const>) scifi_offsets;
    HOST_INPUT(host_scifi_raw_sizes_t, gsl::span<unsigned int const>) scifi_sizes;
    HOST_INPUT(host_scifi_raw_types_t, gsl::span<unsigned int const>) scifi_types;
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_OUTPUT(host_output_event_list_t, unsigned) host_output_event_list;
    HOST_OUTPUT(host_number_of_selected_events_t, unsigned) host_number_of_selected_events;
    MASK_OUTPUT(dev_event_list_output_t) dev_output_event_list;
    PROPERTY(min_clusters_t, "min_clusters", "minimum number of SciFi clusters", unsigned)
    min_clusters;
    PROPERTY(max_clusters_t, "max_clusters", "maximum number of SciFi clusters", unsigned)
    max_clusters;
  };

  // Templated GEC on the MEP layout
  template<bool mep_layout = true>
  void host_scifi_gec(host_scifi_gec::Parameters parameters)
  {
    auto const scifi_offsets = *parameters.scifi_offsets;
    auto const scifi_sizes = *parameters.scifi_sizes;
    auto const scifi_types = *parameters.scifi_types;

    unsigned size_of_list = 0;
    for (unsigned event_index = 0; event_index < parameters.host_number_of_events[0]; ++event_index) {
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

      if (n_SciFi_clusters <= parameters.max_clusters && n_SciFi_clusters >= parameters.min_clusters) {
        parameters.host_output_event_list[size_of_list++] = event_number;
      }
    }
    parameters.host_number_of_selected_events[0] = size_of_list;
  }

  // Algorithm
  struct host_scifi_gec_t : public HostAlgorithm, Parameters {
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
} // namespace host_scifi_gec
