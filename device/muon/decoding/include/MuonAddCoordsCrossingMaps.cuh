/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "MuonRawToHits.cuh"
#include "MuonRaw.cuh"

namespace muon_add_coords_crossing_maps {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_events_t, unsigned), host_number_of_events),
    (HOST_INPUT(host_muon_total_number_of_tiles_t, unsigned), host_muon_total_number_of_tiles),
    (DEVICE_INPUT(dev_storage_station_region_quarter_offsets_t, unsigned), dev_storage_station_region_quarter_offsets),
    (DEVICE_INPUT(dev_storage_tile_id_t, unsigned), dev_storage_tile_id),
    (DEVICE_INPUT(dev_muon_raw_to_hits_t, Muon::MuonRawToHits), dev_muon_raw_to_hits),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_OUTPUT(dev_atomics_index_insert_t, unsigned), dev_atomics_index_insert),
    (DEVICE_OUTPUT(dev_muon_compact_hit_t, uint64_t), dev_muon_compact_hit),
    (DEVICE_OUTPUT(dev_muon_tile_used_t, bool), dev_muon_tile_used),
    (DEVICE_OUTPUT(dev_station_ocurrences_sizes_t, unsigned), dev_station_ocurrences_sizes),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void muon_add_coords_crossing_maps(Parameters);

  struct muon_add_coords_crossing_maps_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace muon_add_coords_crossing_maps