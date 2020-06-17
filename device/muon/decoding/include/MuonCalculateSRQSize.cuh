#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "MuonRawToHits.cuh"
#include "MuonRaw.cuh"

namespace muon_calculate_srq_size {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_selected_events_t, unsigned), host_number_of_selected_events),
    (DEVICE_INPUT(dev_event_list_t, unsigned), dev_event_list),
    (DEVICE_INPUT(dev_muon_raw_t, char), dev_muon_raw),
    (DEVICE_INPUT(dev_muon_raw_offsets_t, unsigned), dev_muon_raw_offsets),
    (DEVICE_OUTPUT(dev_muon_raw_to_hits_t, Muon::MuonRawToHits), dev_muon_raw_to_hits),
    (DEVICE_OUTPUT(dev_storage_station_region_quarter_sizes_t, unsigned), dev_storage_station_region_quarter_sizes))

  __global__ void muon_calculate_srq_size(Parameters);

  __global__ void muon_calculate_srq_size_mep(Parameters);

  struct muon_calculate_srq_size_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;
  };
} // namespace muon_calculate_srq_size
