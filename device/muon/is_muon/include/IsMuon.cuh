#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "States.cuh"
#include "SciFiConsolidated.cuh"

namespace is_muon {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, uint);
    DEVICE_INPUT(dev_offsets_forward_tracks_t, uint) dev_atomics_scifi;
    DEVICE_INPUT(dev_offsets_scifi_track_hit_number, uint) dev_scifi_track_hit_number;
    DEVICE_INPUT(dev_scifi_qop_t, float) dev_scifi_qop;
    DEVICE_INPUT(dev_scifi_states_t, MiniState) dev_scifi_states;
    DEVICE_INPUT(dev_scifi_track_ut_indices_t, uint) dev_scifi_track_ut_indices;
    DEVICE_INPUT(dev_station_ocurrences_offset_t, uint) dev_station_ocurrences_offset;
    DEVICE_INPUT(dev_muon_hits_t, char) dev_muon_hits;
    DEVICE_OUTPUT(dev_muon_track_occupancies_t, int) dev_muon_track_occupancies;
    DEVICE_OUTPUT(dev_is_muon_t, bool) dev_is_muon;
  };

  __global__ void is_muon(
    Parameters,
    const Muon::Constants::FieldOfInterest* dev_muon_foi,
    const float* dev_muon_momentum_cuts);

  template<typename T>
  struct is_muon_t : public DeviceAlgorithm, Parameters {

    decltype(global_function(is_muon)) function {is_muon};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_muon_track_occupancies_t>(
        arguments, Muon::Constants::n_stations * value<host_number_of_reconstructed_scifi_tracks_t>(arguments));
      set_size<dev_is_muon_t>(arguments, value<host_number_of_reconstructed_scifi_tracks_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_muon_track_occupancies_t>(arguments, 0, cuda_stream);

      function(
        dim3(value<host_number_of_selected_events_t>(arguments)), dim3(32, Muon::Constants::n_stations), cuda_stream)(
        Parameters {begin<dev_offsets_forward_tracks_t>(arguments),
                    begin<dev_offsets_scifi_track_hit_number>(arguments),
                    begin<dev_scifi_qop_t>(arguments),
                    begin<dev_scifi_states_t>(arguments),
                    begin<dev_scifi_track_ut_indices_t>(arguments),
                    begin<dev_station_ocurrences_offset_t>(arguments),
                    begin<dev_muon_hits_t>(arguments),
                    begin<dev_muon_track_occupancies_t>(arguments),
                    begin<dev_is_muon_t>(arguments)},
        constants.dev_muon_foi,
        constants.dev_muon_momentum_cuts);

      if (runtime_options.do_check) {
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_is_muon,
          begin<dev_is_muon_t>(arguments),
          size<dev_is_muon_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
      }
    }
  };
} // namespace is_muon