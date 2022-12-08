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

#include <VeloConsolidated.cuh>

namespace muon_lumi_counters {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_lumi_summaries_size_t, unsigned) host_lumi_summaries_size;
    DEVICE_INPUT(dev_lumi_summary_offsets_t, unsigned) dev_lumi_summary_offsets;
    DEVICE_INPUT(dev_storage_station_region_quarter_offsets_t, unsigned) dev_storage_station_region_quarter_offsets;
    DEVICE_OUTPUT(dev_lumi_infos_t, Lumi::LumiInfo) dev_lumi_infos;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
    PROPERTY(lumi_sum_length_t, "lumi_sum_length", "LumiSummary length", unsigned) lumi_sum_length;
    PROPERTY(
      lumi_counter_schema_t,
      "lumi_counter_schema",
      "schema for lumi counters",
      std::map<std::string, std::pair<unsigned, unsigned>>);
    PROPERTY(
      muon_hits_m2r1_offset_and_size_t,
      "muon_hits_m2r1_offset_and_size",
      "offset and size in bits of the Muon hits M2R1 counter",
      std::pair<unsigned, unsigned>)
    muon_hits_m2r1_offset_and_size;
    PROPERTY(
      muon_hits_m2r2_offset_and_size_t,
      "muon_hits_m2r2_offset_and_size",
      "offset and size in bits of the Muon hits M2R2 counter",
      std::pair<unsigned, unsigned>)
    muon_hits_m2r2_offset_and_size;
    PROPERTY(
      muon_hits_m2r3_offset_and_size_t,
      "muon_hits_m2r3_offset_and_size",
      "offset and size in bits of the Muon hits M2R3 counter",
      std::pair<unsigned, unsigned>)
    muon_hits_m2r3_offset_and_size;
    PROPERTY(
      muon_hits_m2r4_offset_and_size_t,
      "muon_hits_m2r4_offset_and_size",
      "offset and size in bits of the Muon hits M2R4 counter",
      std::pair<unsigned, unsigned>)
    muon_hits_m2r4_offset_and_size;
    PROPERTY(
      muon_hits_m3r1_offset_and_size_t,
      "muon_hits_m3r1_offset_and_size",
      "offset and size in bits of the Muon hits M3R1 counter",
      std::pair<unsigned, unsigned>)
    muon_hits_m3r1_offset_and_size;
    PROPERTY(
      muon_hits_m3r2_offset_and_size_t,
      "muon_hits_m3r2_offset_and_size",
      "offset and size in bits of the Muon hits M3R2 counter",
      std::pair<unsigned, unsigned>)
    muon_hits_m3r2_offset_and_size;
    PROPERTY(
      muon_hits_m3r3_offset_and_size_t,
      "muon_hits_m3r3_offset_and_size",
      "offset and size in bits of the Muon hits M3R3 counter",
      std::pair<unsigned, unsigned>)
    muon_hits_m3r3_offset_and_size;
    PROPERTY(
      muon_hits_m3r4_offset_and_size_t,
      "muon_hits_m3r4_offset_and_size",
      "offset and size in bits of the Muon hits M3R4 counter",
      std::pair<unsigned, unsigned>)
    muon_hits_m3r4_offset_and_size;
    PROPERTY(
      muon_hits_m4r1_offset_and_size_t,
      "muon_hits_m4r1_offset_and_size",
      "offset and size in bits of the Muon hits M4R1 counter",
      std::pair<unsigned, unsigned>)
    muon_hits_m4r1_offset_and_size;
    PROPERTY(
      muon_hits_m4r2_offset_and_size_t,
      "muon_hits_m4r2_offset_and_size",
      "offset and size in bits of the Muon hits M4R2 counter",
      std::pair<unsigned, unsigned>)
    muon_hits_m4r2_offset_and_size;
    PROPERTY(
      muon_hits_m4r3_offset_and_size_t,
      "muon_hits_m4r3_offset_and_size",
      "offset and size in bits of the Muon hits M4R3 counter",
      std::pair<unsigned, unsigned>)
    muon_hits_m4r3_offset_and_size;
    PROPERTY(
      muon_hits_m4r4_offset_and_size_t,
      "muon_hits_m4r4_offset_and_size",
      "offset and size in bits of the Muon hits M4R4 counter",
      std::pair<unsigned, unsigned>)
    muon_hits_m4r4_offset_and_size;
  }; // struct Parameters

  __global__ void muon_lumi_counters(Parameters, const unsigned number_of_events);

  struct muon_lumi_counters_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void init();

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{64, 1, 1}}};
    Property<lumi_sum_length_t> m_lumi_sum_length {this, 0u};
    Property<lumi_counter_schema_t> m_lumi_counter_schema {this, {}};
    Property<muon_hits_m2r1_offset_and_size_t> m_muon_hits_m2r1_offset_and_size {this, {0u, 0u}};
    Property<muon_hits_m2r2_offset_and_size_t> m_muon_hits_m2r2_offset_and_size {this, {0u, 0u}};
    Property<muon_hits_m2r3_offset_and_size_t> m_muon_hits_m2r3_offset_and_size {this, {0u, 0u}};
    Property<muon_hits_m2r4_offset_and_size_t> m_muon_hits_m2r4_offset_and_size {this, {0u, 0u}};
    Property<muon_hits_m3r1_offset_and_size_t> m_muon_hits_m3r1_offset_and_size {this, {0u, 0u}};
    Property<muon_hits_m3r2_offset_and_size_t> m_muon_hits_m3r2_offset_and_size {this, {0u, 0u}};
    Property<muon_hits_m3r3_offset_and_size_t> m_muon_hits_m3r3_offset_and_size {this, {0u, 0u}};
    Property<muon_hits_m3r4_offset_and_size_t> m_muon_hits_m3r4_offset_and_size {this, {0u, 0u}};
    Property<muon_hits_m4r1_offset_and_size_t> m_muon_hits_m4r1_offset_and_size {this, {0u, 0u}};
    Property<muon_hits_m4r2_offset_and_size_t> m_muon_hits_m4r2_offset_and_size {this, {0u, 0u}};
    Property<muon_hits_m4r3_offset_and_size_t> m_muon_hits_m4r3_offset_and_size {this, {0u, 0u}};
    Property<muon_hits_m4r4_offset_and_size_t> m_muon_hits_m4r4_offset_and_size {this, {0u, 0u}};
  }; // struct muon_lumi_counters_t
} // namespace muon_lumi_counters
