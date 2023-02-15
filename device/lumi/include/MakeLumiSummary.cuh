/*****************************************************************************\
* (c) Copyright 2022 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"
#include "AlgorithmTypes.cuh"
#include "GenericContainerContracts.h"

#include <LumiDefinitions.cuh>
#include "ODINBank.cuh"

namespace make_lumi_summary {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_lumi_summaries_size_t, unsigned) host_lumi_summaries_size;
    DEVICE_INPUT(dev_lumi_summary_offsets_t, unsigned) dev_lumi_summary_offsets;
    DEVICE_INPUT(dev_odin_data_t, ODINData) dev_odin_data;
    DEVICE_INPUT(dev_velo_info_t, Lumi::LumiInfo) dev_velo_info;
    DEVICE_INPUT(dev_pv_info_t, Lumi::LumiInfo) dev_pv_info;
    DEVICE_INPUT(dev_scifi_info_t, Lumi::LumiInfo) dev_scifi_info;
    DEVICE_INPUT(dev_muon_info_t, Lumi::LumiInfo) dev_muon_info;
    DEVICE_INPUT(dev_calo_info_t, Lumi::LumiInfo) dev_calo_info;
    DEVICE_INPUT(dev_plume_info_t, Lumi::LumiInfo) dev_plume_info;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_OUTPUT(dev_lumi_summaries_t, unsigned) dev_lumi_summaries;
    HOST_OUTPUT(host_lumi_summaries_t, unsigned) host_lumi_summaries;
    HOST_OUTPUT(host_lumi_summary_offsets_t, unsigned) host_lumi_summary_offsets;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
    PROPERTY(encoding_key_t, "encoding_key", "encoding key", unsigned) key;
    PROPERTY(lumi_sum_length_t, "lumi_sum_length", "LumiSummary length", unsigned) lumi_sum_length;
    PROPERTY(
      lumi_counter_schema_t,
      "lumi_counter_schema",
      "schema for lumi counters",
      std::map<std::string, std::pair<unsigned, unsigned>>);
    PROPERTY(
      basic_offsets_and_sizes_t,
      "basic_offsets_and_sizes",
      "offsets and sizes in bits for the ODIN and GEC counters",
      std::array<unsigned, 2 * Lumi::Constants::n_basic_counters>)
    basic_offsets_and_sizes;
  }; // struct Parameters

  __global__ void make_lumi_summary(
    Parameters,
    const unsigned number_of_events,
    const unsigned number_of_events_passed_gec,
    std::array<const Lumi::LumiInfo*, Lumi::Constants::n_sub_infos> lumiInfos,
    std::array<unsigned, Lumi::Constants::n_sub_infos> spanSize,
    const unsigned size_of_aggregate);

  __device__ void setField(unsigned offset, unsigned size, unsigned* target, unsigned value);

  struct make_lumi_summary_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void init();

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{64, 1, 1}}};
    Property<encoding_key_t> m_key {this, 0};
    Property<lumi_sum_length_t> m_lumi_sum_length {this, 0u};
    Property<lumi_counter_schema_t> m_lumi_counter_schema {this, {}};
    Property<basic_offsets_and_sizes_t> m_basic_offsets_and_sizes {this,
                                                                   {{0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u}}};
  }; // struct make_lumi_summary_t
} // namespace make_lumi_summary
