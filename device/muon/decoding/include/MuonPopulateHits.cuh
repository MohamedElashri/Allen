#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "FindPermutation.cuh"
#include "MuonRawToHits.cuh"
#include "MuonEventModel.cuh"

namespace muon_populate_hits {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, uint), host_number_of_selected_events),
    (HOST_INPUT(host_muon_total_number_of_hits_t, uint), host_muon_total_number_of_hits),
    (DEVICE_INPUT(dev_storage_tile_id_t, uint), dev_storage_tile_id),
    (DEVICE_INPUT(dev_storage_tdc_value_t, uint), dev_storage_tdc_value),
    (DEVICE_OUTPUT(dev_permutation_station_t, uint), dev_permutation_station),
    (DEVICE_OUTPUT(dev_muon_hits_t, char), dev_muon_hits),
    (DEVICE_INPUT(dev_station_ocurrences_offset_t, uint), dev_station_ocurrences_offset),
    (DEVICE_INPUT(dev_muon_compact_hit_t, uint64_t), dev_muon_compact_hit),
    (DEVICE_INPUT(dev_muon_raw_to_hits_t, Muon::MuonRawToHits), dev_muon_raw_to_hits),
    (DEVICE_INPUT(dev_storage_station_region_quarter_offsets_t, uint), dev_storage_station_region_quarter_offsets),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void muon_populate_hits(Parameters);

  struct muon_populate_hits_t : public DeviceAlgorithm, Parameters {
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
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{256, 1, 1}}};
  };
} // namespace muon_populate_hits