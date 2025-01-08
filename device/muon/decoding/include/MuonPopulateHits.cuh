/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "MuonDefinitions.cuh"
#include "MuonRawToHits.cuh"
#include "MuonEventModel.cuh"

namespace muon_populate_hits {
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    HOST_INPUT(host_muon_total_number_of_hits_t, unsigned) host_muon_total_number_of_hits;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_storage_tile_id_t, unsigned) dev_storage_tile_id;
    DEVICE_INPUT(dev_storage_tdc_value_t, unsigned) dev_storage_tdc_value;
    DEVICE_INPUT(dev_station_ocurrences_offset_t, unsigned) dev_station_ocurrences_offset;
    DEVICE_INPUT(dev_muon_compact_hit_t, uint64_t) dev_muon_compact_hit;
    DEVICE_INPUT(dev_storage_station_region_quarter_offsets_t, unsigned) dev_storage_station_region_quarter_offsets;
    DEVICE_OUTPUT(dev_muon_hits_t, char) dev_muon_hits;
  };

  __global__ void muon_populate_hits(Parameters, const Muon::MuonTables*);

  struct muon_populate_hits_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {128, 1, 1}, "block dimensions"};
  };
} // namespace muon_populate_hits