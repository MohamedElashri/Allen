#pragma once

#include "UTMagnetToolDefinitions.h"
#include "UTDefinitions.cuh"
#include "VeloDefinitions.cuh"
#include "CompassUTDefinitions.cuh"
#include "FindBestHits.cuh"
#include "DeviceAlgorithm.cuh"
#include "UTEventModel.cuh"

//=========================================================================
// Function definitions
//=========================================================================
namespace compass_ut {
  struct Parameters {
    HOST_INPUT(host_number_of_selected_events_t, uint);
    DEVICE_INPUT(dev_ut_hits_t, char) dev_ut_hits; // actual hit content
    DEVICE_INPUT(dev_ut_hit_offsets_t, uint) dev_ut_hit_offsets;
    DEVICE_INPUT(dev_atomics_velo_t, uint) dev_atomics_velo; // prefixsum, offset to tracks
    DEVICE_INPUT(dev_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_states_t, char) dev_velo_states;
    DEVICE_OUTPUT(dev_ut_active_tracks_t, uint) dev_ut_active_tracks;
    DEVICE_OUTPUT(dev_ut_tracks_t, UT::TrackHits) dev_ut_tracks;
    DEVICE_OUTPUT(dev_atomics_ut_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_ut_windows_layers_t, short) dev_ut_windows_layers;
    DEVICE_INPUT(dev_accepted_velo_tracks_t, bool) dev_accepted_velo_tracks;
  };

  __global__ void compass_ut(
    Parameters,
    UTMagnetTool* dev_ut_magnet_tool,
    const float* dev_magnet_polarity,
    const float* dev_ut_dxDy,
    const uint* dev_unique_x_sector_layer_offsets);

  __device__ void compass_ut_tracking(
    const short* dev_windows_layers,
    const uint number_of_tracks_event,
    const int i_track,
    const uint current_track_offset,
    Velo::Consolidated::ConstStates& velo_states,
    UT::ConstHits& ut_hits,
    const UT::HitOffsets& ut_hit_offsets,
    const float* bdl_table,
    const float* dev_ut_dxDy,
    const float magnet_polarity,
    short* win_size_shared,
    uint* n_veloUT_tracks_event,
    UT::TrackHits* veloUT_tracks_event,
    const int event_hit_offset);

  __host__ __device__ __inline__ bool velo_track_in_UT_acceptance(const MiniState& state);

  __device__ __inline__ void fill_shared_windows(
    const short* windows_layers,
    const int number_of_tracks_event,
    const int i_track,
    short* win_size_shared);

  __device__ __inline__ bool
  found_active_windows(const short* dev_windows_layers, const int total_tracks_event, const int track);

  __device__ void save_track(
    const int i_track,
    const float* bdlTable,
    const MiniState& velo_state,
    const BestParams& best_params,
    const int* best_hits,
    UT::ConstHits& ut_hits,
    const float* ut_dxDy,
    const float magSign,
    uint* n_veloUT_tracks,
    UT::TrackHits* VeloUT_tracks,
    const int event_hit_offset);

  template<typename T>
  struct compass_ut_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name {"compass_ut_t"};
    decltype(global_function(compass_ut)) function {compass_ut};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_ut_tracks_t>(arguments,
        value<host_number_of_selected_events_t>(arguments) * UT::Constants::max_num_tracks);
      set_size<dev_atomics_ut_t>(arguments, value<host_number_of_selected_events_t>(arguments) * UT::num_atomics);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      cudaCheck(cudaMemsetAsync(
        offset<dev_ut_active_tracks_t>(arguments), 0, size<dev_ut_active_tracks_t>(arguments), cuda_stream));
      cudaCheck(cudaMemsetAsync(offset<dev_atomics_ut_t>(arguments), 0, size<dev_atomics_ut_t>(arguments), cuda_stream));

      function(
        dim3(value<host_number_of_selected_events_t>(arguments)), dim3(UT::Constants::num_thr_compassut), cuda_stream)(
        Parameters {offset<dev_ut_hits_t>(arguments),
                   offset<dev_ut_hit_offsets_t>(arguments),
                   offset<dev_atomics_velo_t>(arguments),
                   offset<dev_velo_track_hit_number_t>(arguments),
                   offset<dev_velo_states_t>(arguments),
                   offset<dev_ut_active_tracks_t>(arguments),
                   offset<dev_ut_tracks_t>(arguments),
                   offset<dev_atomics_ut_t>(arguments),
                   offset<dev_ut_windows_layers_t>(arguments),
                   offset<dev_accepted_velo_tracks_t>(arguments)},
        constants.dev_ut_magnet_tool,
        constants.dev_magnet_polarity.data(),
        constants.dev_ut_dxDy.data(),
        constants.dev_unique_x_sector_layer_offsets.data());
    }

  private:
    Property<float> m_slope {this,
                             "sigma_velo_slope",
                             Configuration::compass_ut_t::sigma_velo_slope,
                             0.010f * Gaudi::Units::mrad,
                             "sigma velo slope [radians]"};
    DerivedProperty<float> m_inv_slope {this,
                                        "inv_sigma_velo_slope",
                                        Configuration::compass_ut_t::inv_sigma_velo_slope,
                                        Configuration::Relations::inverse,
                                        std::vector<Property<float>*> {&this->m_slope},
                                        "inv sigma velo slope"};
    Property<float> m_mom_fin {this,
                               "min_momentum_final",
                               Configuration::compass_ut_t::min_momentum_final,
                               2.5f * Gaudi::Units::GeV,
                               "final min momentum cut [MeV/c]"};
    Property<float> m_pt_fin {this,
                              "min_pt_final",
                              Configuration::compass_ut_t::min_pt_final,
                              0.425f * Gaudi::Units::GeV,
                              "final min pT cut [MeV/c]"};
    Property<float> m_hit_tol_2 {this,
                                 "hit_tol_2",
                                 Configuration::compass_ut_t::hit_tol_2,
                                 0.8f * Gaudi::Units::mm,
                                 "hit_tol_2 [mm]"};
    Property<float> m_delta_tx_2 {this, "delta_tx_2", Configuration::compass_ut_t::delta_tx_2, 0.018f, "delta_tx_2"};
    Property<uint> m_max_considered_before_found {this,
                                                  "max_considered_before_found",
                                                  Configuration::compass_ut_t::max_considered_before_found,
                                                  6u,
                                                  "max_considered_before_found"};
  };
} // namespace compass_ut