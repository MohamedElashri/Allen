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

#include "PV_Definitions.cuh"

namespace pv_lumi_counters {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_lumi_summaries_size_t, unsigned) host_lumi_summaries_size;
    DEVICE_INPUT(dev_lumi_summary_offsets_t, unsigned) dev_lumi_summary_offsets;
    DEVICE_INPUT(dev_multi_final_vertices_t, PV::Vertex) dev_multi_final_vertices;
    DEVICE_INPUT(dev_number_of_pvs_t, unsigned) dev_number_of_pvs;
    DEVICE_OUTPUT(dev_lumi_infos_t, Lumi::LumiInfo) dev_lumi_infos;
    PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions) block_dim;
    PROPERTY(lumi_counter_schema_t, "lumi_counter_schema", "schema for lumi counters", std::map<std::string,std::pair<unsigned,unsigned>>);
    PROPERTY(velo_vertices_offset_t, "velo_vertices_offset", "offset to the velo vertices counter", unsigned) velo_vertices_offset;
    PROPERTY(velo_vertices_size_t, "velo_vertices_size", "size in bits of the velo vertices counter", unsigned) velo_vertices_size;
  }; // struct Parameters

  __global__ void pv_lumi_counters(Parameters, const unsigned number_of_events);

  struct pv_lumi_counters_t : public DeviceAlgorithm, Parameters {
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
    Property<velo_vertices_offset_t> m_velo_vertices_offset {this, 0u};
    Property<velo_vertices_size_t> m_velo_vertices_size {this, 0u};
  }; // struct pv_lumi_counters_t
} // namespace pv_lumi_counters
