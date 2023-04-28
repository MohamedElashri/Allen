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

namespace scifi_lumi_counters {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_lumi_summaries_count_t, unsigned) host_lumi_summaries_count;
    DEVICE_INPUT(dev_lumi_event_indices_t, unsigned) dev_lumi_event_indices;
    DEVICE_INPUT(dev_scifi_hit_offsets_t, unsigned) dev_scifi_hit_offsets;
    DEVICE_INPUT(dev_scifi_hits_t, char) dev_scifi_hits;
    DEVICE_OUTPUT(dev_lumi_infos_t, Lumi::LumiInfo) dev_lumi_infos;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
    PROPERTY(
      lumi_counter_schema_t,
      "lumi_counter_schema",
      "schema for lumi counters",
      std::map<std::string, std::pair<unsigned, unsigned>>)
    lumi_counter_schema;
    PROPERTY(
      lumi_counter_shifts_and_scales_t,
      "lumi_counter_shifts_and_scales",
      "shifts and scales extracted from the schema for lumi counters",
      std::map<std::string, std::pair<float, float>>)
    lumi_counter_shifts_and_scales;
    PROPERTY(
      scifi_offsets_and_sizes_t,
      "scifi_offsets_and_sizes",
      "offsets and sizes in bits for the SciFi counters",
      std::array<unsigned, 2 * Lumi::Constants::n_scifi_counters>)
    scifi_offsets_and_sizes;
    PROPERTY(
      scifi_shifts_and_scales_t,
      "scifi_shifts_and_scales",
      "shifts and scales for the SciFi counters",
      std::array<float, 2 * Lumi::Constants::n_scifi_counters>)
    scifi_shifts_and_scales;
  }; // struct Parameters

  __global__ void scifi_lumi_counters(Parameters, const unsigned number_of_events, const char* scifi_geometry);

  struct scifi_lumi_counters_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void init();

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{64, 1, 1}}};
    Property<lumi_counter_schema_t> m_lumi_counter_schema {this, {}};
    Property<lumi_counter_shifts_and_scales_t> m_lumi_counter_shifts_and_scales {this, {}};
    Property<scifi_offsets_and_sizes_t> m_scifi_offsets_and_sizes {this,
                                                                   {{0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u, 0u}}};
    Property<scifi_shifts_and_scales_t> m_scifi_shifts_and_scales {
      this,
      {{0.f, 1.f, 0.f, 1.f, 0.f, 1.f, 0.f, 1.f, 0.f, 1.f, 0.f, 1.f}}};
  }; // struct scifi_lumi_counters_t
} // namespace scifi_lumi_counters
