#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "States.cuh"
#include "SciFiConsolidated.cuh"

enum offset {
  DTS = 0,
  TIMES = 1 * Muon::Constants::n_stations,
  CROSS = 2 * Muon::Constants::n_stations,
  RES_X = 3 * Muon::Constants::n_stations,
  RES_Y = 4 * Muon::Constants::n_stations
};

namespace muon_catboost_features_extraction {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, uint);
    DEVICE_INPUT(dev_atomics_scifi_t, uint) dev_atomics_scifi;
    DEVICE_INPUT(dev_scifi_track_hit_number_t, uint) dev_scifi_track_hit_number;
    DEVICE_INPUT(dev_scifi_qop_t, float) dev_scifi_qop;
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_INPUT(dev_scifi_track_ut_indices_t, uint) dev_scifi_track_ut_indices;
    DEVICE_INPUT(dev_muon_hits_t, Muon::HitsSoA) dev_muon_hits;
    DEVICE_OUTPUT(dev_muon_catboost_features_t, float) dev_muon_catboost_features;
  };

  __global__ void muon_catboost_features_extraction(Parameters);

  template<typename T>
  struct muon_catboost_features_extraction_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name {"muon_catboost_features_extraction_t"};
    decltype(global_function(muon_catboost_features_extraction)) function {muon_catboost_features_extraction};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_muon_catboost_features_t>(
        arguments,
        Muon::Constants::n_catboost_features * value<host_number_of_reconstructed_scifi_tracks_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      function(
        dim3(value<host_number_of_selected_events_t>(arguments), Muon::Constants::n_stations),
        block_dimension(),
        cuda_stream)(Parameters {offset<dev_atomics_scifi_t>(arguments),
                                 offset<dev_scifi_track_hit_number_t>(arguments),
                                 offset<dev_scifi_qop_t>(arguments),
                                 offset<dev_scifi_states_t>(arguments),
                                 offset<dev_scifi_track_ut_indices_t>(arguments),
                                 offset<dev_muon_hits_t>(arguments),
                                 offset<dev_muon_catboost_features_t>(arguments)});
    }
  };
} // namespace muon_catboost_features_extraction