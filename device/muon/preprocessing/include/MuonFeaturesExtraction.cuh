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
    DEVICE_INPUT(dev_station_ocurrences_offset_t, uint) dev_station_ocurrences_offset;
    DEVICE_INPUT(dev_muon_hits_t, char) dev_muon_hits;
    DEVICE_OUTPUT(dev_muon_catboost_features_t, float) dev_muon_catboost_features;
    PROPERTY(block_dim_t, DeviceDimensions, "block_dim", "block dimensions");
  };

  __global__ void muon_catboost_features_extraction(Parameters);

  template<typename T>
  struct muon_catboost_features_extraction_t : public DeviceAlgorithm, Parameters {

    decltype(global_function(muon_catboost_features_extraction)) function {muon_catboost_features_extraction};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_muon_catboost_features_t>(
        arguments,
        Muon::Constants::n_catboost_features * first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants&,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      function(
        dim3(first<host_number_of_selected_events_t>(arguments), Muon::Constants::n_stations),
        property<block_dim_t>(),
        cuda_stream)(Parameters {data<dev_atomics_scifi_t>(arguments),
                                 data<dev_scifi_track_hit_number_t>(arguments),
                                 data<dev_scifi_qop_t>(arguments),
                                 data<dev_scifi_states_t>(arguments),
                                 data<dev_scifi_track_ut_indices_t>(arguments),
                                 data<dev_station_ocurrences_offset_t>(arguments),
                                 data<dev_muon_hits_t>(arguments),
                                 data<dev_muon_catboost_features_t>(arguments)});
    }

  private:
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
  };
} // namespace muon_catboost_features_extraction