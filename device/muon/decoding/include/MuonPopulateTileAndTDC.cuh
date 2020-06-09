#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "MuonRawToHits.cuh"
#include "MuonRaw.cuh"

namespace muon_populate_tile_and_tdc {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, uint), host_number_of_selected_events),
    (HOST_INPUT(host_muon_total_number_of_tiles_t, uint), host_muon_total_number_of_tiles),
    (DEVICE_INPUT(dev_event_list_t, uint), dev_event_list),
    (DEVICE_INPUT(dev_muon_raw_t, char), dev_muon_raw),
    (DEVICE_INPUT(dev_muon_raw_offsets_t, uint), dev_muon_raw_offsets),
    (DEVICE_INPUT(dev_muon_raw_to_hits_t, Muon::MuonRawToHits), dev_muon_raw_to_hits),
    (DEVICE_INPUT(dev_storage_station_region_quarter_offsets_t, uint), dev_storage_station_region_quarter_offsets),
    (DEVICE_OUTPUT(dev_storage_tile_id_t, uint), dev_storage_tile_id),
    (DEVICE_OUTPUT(dev_storage_tdc_value_t, uint), dev_storage_tdc_value),
    (DEVICE_OUTPUT(dev_atomics_muon_t, uint), dev_atomics_muon))

  __global__ void muon_populate_tile_and_tdc(Parameters);

  __global__ void muon_populate_tile_and_tdc_mep(Parameters);

  struct muon_populate_tile_and_tdc_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;
  };
} // namespace muon_populate_tile_and_tdc
