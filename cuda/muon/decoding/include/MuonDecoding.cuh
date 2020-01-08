#pragma once

#include "CudaCommon.h"
#include "DeviceAlgorithm.cuh"
#include "ArgumentsMuon.cuh"
#include "MuonDefinitions.cuh"
#include "MuonRawToHits.cuh"

__global__ void muon_decoding(
  const uint* event_list,
  const char* events,
  const unsigned int* offsets,
  Muon::MuonRawToHits* muon_raw_to_hits,
  Muon::HitsSoA* muon_hits);

struct muon_decoding_t : public DeviceAlgorithm {
  constexpr static auto name {"muon_decoding_t"};
  decltype(global_function(muon_decoding)) function {muon_decoding};
  using Arguments = std::tuple<dev_event_list, dev_muon_raw, dev_muon_raw_offsets, dev_muon_raw_to_hits, dev_muon_hits>;

  void set_arguments_size(
    ArgumentRefManager<T> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const;

  void operator()(
    const ArgumentRefManager<T>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
