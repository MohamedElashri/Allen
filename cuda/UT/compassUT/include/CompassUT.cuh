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
    DEVICE_INPUT(dev_offsets_all_velo_tracks_t, uint) dev_atomics_velo; // prefixsum, offset to tracks
    DEVICE_INPUT(dev_offsets_velo_track_hit_number_t, uint) dev_velo_track_hit_number;
    DEVICE_INPUT(dev_velo_states_t, char) dev_velo_states;
    DEVICE_OUTPUT(dev_ut_tracks_t, UT::TrackHits) dev_ut_tracks;
    DEVICE_OUTPUT(dev_atomics_ut_t, uint) dev_atomics_ut;
    DEVICE_INPUT(dev_ut_windows_layers_t, short) dev_ut_windows_layers;
    DEVICE_INPUT(dev_ut_number_of_selected_velo_tracks_with_windows_t, uint) dev_ut_number_of_selected_velo_tracks;
    DEVICE_INPUT(dev_ut_selected_velo_tracks_with_windows_t, uint) dev_ut_selected_velo_tracks;

    PROPERTY(sigma_velo_slope_t, float, "sigma_velo_slope", "sigma velo slope [radians]")
    sigma_velo_slope;
    PROPERTY(
      min_momentum_final_t,
      float,
      "min_momentum_final",
      "final min momentum cut [MeV/c]")
    min_momentum_final;
    PROPERTY(min_pt_final_t, float, "min_pt_final", "final min pT cut [MeV/c]")
    min_pt_final;
    PROPERTY(hit_tol_2_t, float, "hit_tol_2", "hit_tol_2 [mm]") hit_tol_2;
    PROPERTY(delta_tx_2_t, float, "delta_tx_2", "delta_tx_2") delta_tx_2;
    PROPERTY(max_considered_before_found_t, uint, "max_considered_before_found", "max_considered_before_found")
    max_considered_before_found;
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
    const int event_hit_offset,
    const float min_momentum_final,
    const float min_pt_final,
    const uint max_considered_before_found,
    const float delta_tx_2,
    const float hit_tol_2,
    const float sigma_velo_slope);

  __host__ __device__ __inline__ bool velo_track_in_UT_acceptance(const MiniState& state);

  __device__ __inline__ void fill_shared_windows(
    const short* windows_layers,
    const int number_of_tracks_event,
    const int i_track,
    short* win_size_shared);

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
    const int event_hit_offset,
    const float min_momentum_final,
    const float min_pt_final);

  template<typename T, char... S>
  struct compass_ut_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(compass_ut)) function {compass_ut};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const
    {
      set_size<dev_ut_tracks_t>(
        arguments, value<host_number_of_selected_events_t>(arguments) * UT::Constants::max_num_tracks);
      set_size<dev_atomics_ut_t>(arguments, value<host_number_of_selected_events_t>(arguments) * UT::num_atomics);
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      HostBuffers&,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const
    {
      initialize<dev_atomics_ut_t>(arguments, 0, cuda_stream);

      function(
        dim3(value<host_number_of_selected_events_t>(arguments)), dim3(UT::Constants::num_thr_compassut), cuda_stream)(
        Parameters {begin<dev_ut_hits_t>(arguments),
                    begin<dev_ut_hit_offsets_t>(arguments),
                    begin<dev_offsets_all_velo_tracks_t>(arguments),
                    begin<dev_offsets_velo_track_hit_number_t>(arguments),
                    begin<dev_velo_states_t>(arguments),
                    begin<dev_ut_tracks_t>(arguments),
                    begin<dev_atomics_ut_t>(arguments),
                    begin<dev_ut_windows_layers_t>(arguments),
                    begin<dev_ut_number_of_selected_velo_tracks_with_windows_t>(arguments),
                    begin<dev_ut_selected_velo_tracks_with_windows_t>(arguments),
                    property<sigma_velo_slope_t>(),
                    property<min_momentum_final_t>(),
                    property<min_pt_final_t>(),
                    property<hit_tol_2_t>(),
                    property<delta_tx_2_t>(),
                    property<max_considered_before_found_t>()},
        constants.dev_ut_magnet_tool,
        constants.dev_magnet_polarity.data(),
        constants.dev_ut_dxDy.data(),
        constants.dev_unique_x_sector_layer_offsets.data());
    }

  private:
    Property<sigma_velo_slope_t> m_slope {this, 0.1f * Gaudi::Units::mrad};
    Property<min_momentum_final_t> m_mom_fin {this, 2500.f};
    Property<min_pt_final_t> m_pt_fin {this, 425.f};
    Property<hit_tol_2_t> m_hit_tol_2 {this, 0.8f * Gaudi::Units::mm};
    Property<delta_tx_2_t> m_delta_tx_2 {this, 0.018f};
    Property<max_considered_before_found_t> m_max_considered_before_found {this, 6};
  };
} // namespace compass_ut
