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
    DEVICE_INPUT(dev_lumi_event_indices_t, unsigned) dev_lumi_event_indices;
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
  };

  using offsets_and_sizes_t = std::array<unsigned, 2 * Lumi::Constants::n_basic_counters>;

  __global__ void make_lumi_summary(
    Parameters,
    const unsigned number_of_events,
    const unsigned number_of_events_passed_gec,
    const offsets_and_sizes_t offsets_and_sizes,
    std::array<const Lumi::LumiInfo*, Lumi::Constants::n_sub_infos> lumiInfos,
    std::array<unsigned, Lumi::Constants::n_sub_infos> spanSize,
    const unsigned size_of_aggregate,
    const unsigned lumi_sum_length,
    const unsigned key_full,
    const unsigned key);

  __device__ void setField(unsigned offset, unsigned size, unsigned* target, unsigned value, unsigned summary_length);

  struct make_lumi_summary_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void init();

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {64, 1, 1}, "block dimensions"};
    Allen::Property<unsigned> m_key {this, "encoding_key", 0, "encoding key"};
    Allen::Property<unsigned> m_key_full {this, "encoding_key_full", 0, "encoding key for 1kHz line"};
    Allen::Property<unsigned> m_lumi_sum_length {this, "lumi_sum_length", 0u, "LumiSummary length"};
    Allen::Property<std::map<std::string, std::pair<unsigned, unsigned>>> m_lumi_counter_schema {
      this,
      "lumi_counter_schema",
      {},
      "schema for lumi counters"};

    offsets_and_sizes_t m_offsets_and_sizes {0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u};
  };
} // namespace make_lumi_summary
