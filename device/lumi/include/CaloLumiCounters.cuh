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

#include "CaloDigit.cuh"

namespace calo_lumi_counters {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_lumi_summaries_size_t, unsigned) host_lumi_summaries_size;
    DEVICE_INPUT(dev_lumi_summary_offsets_t, unsigned) dev_lumi_summary_offsets;
    DEVICE_INPUT(dev_ecal_digits_t, CaloDigit) dev_ecal_digits;
    DEVICE_INPUT(dev_ecal_digits_offsets_t, unsigned) dev_ecal_digits_offsets;
    DEVICE_OUTPUT(dev_lumi_infos_t, Lumi::LumiInfo) dev_lumi_infos;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
    PROPERTY(lumi_sum_length_t, "lumi_sum_length", "LumiSummary length", unsigned) lumi_sum_length;
    PROPERTY(
      lumi_counter_schema_t,
      "lumi_counter_schema",
      "schema for lumi counters",
      std::map<std::string, std::pair<unsigned, unsigned>>);
    PROPERTY(ecal_et_offset_and_size_t, "ecal_et_offset_and_size", "offset and size in bits of the ECAL ET counter", std::pair<unsigned, unsigned>)
    ecal_et_offset_and_size;
    PROPERTY(ecal_e_outer_top_offset_and_size_t, "ecal_e_outer_top_offset_and_size", "offset and size in bits of the ECAL E outer top counter", std::pair<unsigned, unsigned>)
    ecal_e_outer_top_offset_and_size;
    PROPERTY(ecal_e_middle_top_offset_and_size_t, "ecal_e_middle_top_offset_and_size", "offset and size in bits of the ECAL E middle top counter", std::pair<unsigned, unsigned>)
    ecal_e_middle_top_offset_and_size;
    PROPERTY(ecal_e_inner_top_offset_and_size_t, "ecal_e_inner_top_offset_and_size", "offset and size in bits of the ECAL E inner top counter", std::pair<unsigned, unsigned>)
    ecal_e_inner_top_offset_and_size;
    PROPERTY(ecal_e_outer_bottom_offset_and_size_t, "ecal_e_outer_bottom_offset_and_size", "offset and size in bits of the ECAL E outer bottom counter", std::pair<unsigned, unsigned>)
    ecal_e_outer_bottom_offset_and_size;
    PROPERTY(ecal_e_middle_bottom_offset_and_size_t, "ecal_e_middle_bottom_offset_and_size", "offset and size in bits of the ECAL E middle bottom counter", std::pair<unsigned, unsigned>)
    ecal_e_middle_bottom_offset_and_size;
    PROPERTY(ecal_e_inner_bottom_offset_and_size_t, "ecal_e_inner_bottom_offset_and_size", "offset and size in bits of the ECAL E inner bottom counter", std::pair<unsigned, unsigned>)
    ecal_e_inner_bottom_offset_and_size;
  }; // struct Parameters

  __global__ void calo_lumi_counters(Parameters, const unsigned number_of_events, const char* raw_ecal_geometry);

  struct calo_lumi_counters_t : public DeviceAlgorithm, Parameters {
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
    Property<ecal_et_offset_and_size_t> m_ecal_et_offset_and_size {this, {0u, 0u}};
    Property<ecal_e_outer_top_offset_and_size_t> m_ecal_e_outer_top_offset_and_size {this, {0u, 0u}};
    Property<ecal_e_middle_top_offset_and_size_t> m_ecal_e_middle_top_offset_and_size {this, {0u, 0u}};
    Property<ecal_e_inner_top_offset_and_size_t> m_ecal_e_inner_top_offset_and_size {this, {0u, 0u}};
    Property<ecal_e_outer_bottom_offset_and_size_t> m_ecal_e_outer_bottom_offset_and_size {this, {0u, 0u}};
    Property<ecal_e_middle_bottom_offset_and_size_t> m_ecal_e_middle_bottom_offset_and_size {this, {0u, 0u}};
    Property<ecal_e_inner_bottom_offset_and_size_t> m_ecal_e_inner_bottom_offset_and_size {this, {0u, 0u}};
  }; // struct calo_lumi_counters_t
} // namespace calo_lumi_counters
