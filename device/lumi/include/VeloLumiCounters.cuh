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

namespace velo_lumi_counters {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_lumi_summaries_size_t, unsigned) host_lumi_summaries_size;
    DEVICE_INPUT(dev_lumi_summary_offsets_t, unsigned) dev_lumi_summary_offsets;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, unsigned) dev_offsets_all_velo_tracks;
    DEVICE_OUTPUT(dev_lumi_infos_t, Lumi::LumiInfo) dev_lumi_infos;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
    PROPERTY(lumi_sum_length_t, "lumi_sum_length", "LumiSummary length", unsigned) lumi_sum_length;
    PROPERTY(
      lumi_counter_schema_t,
      "lumi_counter_schema",
      "schema for lumi counters",
      std::map<std::string, std::pair<unsigned, unsigned>>);
    PROPERTY(
      velo_offsets_and_sizes_t,
      "velo_offsets_and_sizes",
      "offsets and sizes in bits for the VELO counters",
      std::array<std::pair<unsigned, unsigned>, Lumi::Constants::n_velo_counters>)
    velo_offsets_and_sizes;
  }; // struct Parameters

  __global__ void velo_lumi_counters(Parameters, const unsigned number_of_events);

  struct velo_lumi_counters_t : public DeviceAlgorithm, Parameters {
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
    Property<velo_offsets_and_sizes_t> m_velo_offsets_and_sizes {this, {{{0u, 0u}}}};
  }; // struct velo_lumi_counters_t
} // namespace velo_lumi_counters
