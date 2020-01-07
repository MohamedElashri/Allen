#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "States.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsMuon.cuh"
#include "SciFiConsolidated.cuh"

enum offset {
  DTS = 0,
  TIMES = 1 * Muon::Constants::n_stations,
  CROSS = 2 * Muon::Constants::n_stations,
  RES_X = 3 * Muon::Constants::n_stations,
  RES_Y = 4 * Muon::Constants::n_stations
};

__global__ void muon_catboost_features_extraction(
  uint* dev_atomics_scifi,
  uint* dev_scifi_track_hit_number,
  float* dev_scifi_qop,
  MiniState* dev_scifi_states,
  uint* dev_scifi_track_ut_indices,
  const Muon::HitsSoA* muon_hits,
  float* dev_muon_catboost_features);

struct muon_catboost_features_extraction_t : public DeviceAlgorithm {
  constexpr static auto name {"muon_catboost_features_extraction_t"};
  decltype(global_function(muon_catboost_features_extraction)) function {muon_catboost_features_extraction};
  using Arguments = std::tuple<
    dev_atomics_scifi,
    dev_scifi_track_hit_number,
    dev_scifi_qop,
    dev_scifi_states,
    dev_scifi_track_ut_indices,
    dev_muon_hits,
    dev_muon_catboost_features>;

  void set_arguments_size(
    ArgumentRefManager<Arguments> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const;

  void operator()(
    const ArgumentRefManager<Arguments>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
