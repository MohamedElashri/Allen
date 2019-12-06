#pragma once

#include "UTMagnetToolDefinitions.h"
#include "UTDefinitions.cuh"
#include "VeloDefinitions.cuh"
#include "CompassUTDefinitions.cuh"
#include "FindBestHits.cuh"
#include "GpuAlgorithm.cuh"
#include "ArgumentsCommon.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsUT.cuh"
#include "UTEventModel.cuh"

//=========================================================================
// Functions definitions
//=========================================================================
__global__ void compass_ut(
  uint* dev_ut_hits,
  const uint* dev_ut_hit_offsets,
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number,
  char* dev_velo_states,
  UTMagnetTool* dev_ut_magnet_tool,
  const float* dev_magnet_polarity,
  const float* dev_ut_dxDy,
  uint* dev_active_tracks,
  const uint* dev_unique_x_sector_layer_offsets,
  UT::TrackHits* dev_compassUT_tracks,
  uint* dev_atomics_compassUT,
  short* dev_windows_layers,
  bool* dev_accepted_velo_tracks);

__device__ void compass_ut_tracking(
  const short* dev_windows_layers,
  const uint number_of_tracks_event,
  const int i_track,
  const uint current_track_offset,
  const Velo::Consolidated::States& velo_states,
  const UT::Hits& ut_hits,
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
  const UT::Hits& ut_hits,
  const float* ut_dxDy,
  const float magSign,
  uint* n_veloUT_tracks,
  UT::TrackHits* VeloUT_tracks,
  const int event_hit_offset);

struct compass_ut_t : public GpuAlgorithm {
  constexpr static auto name {"compass_ut_t"};
  decltype(gpu_function(compass_ut)) function {compass_ut};
  using Arguments = std::tuple<
    dev_ut_hits,
    dev_ut_hit_offsets,
    dev_atomics_velo,
    dev_velo_track_hit_number,
    dev_velo_states,
    dev_ut_tracks,
    dev_atomics_ut,
    dev_ut_active_tracks,
    dev_ut_windows_layers,
    dev_accepted_velo_tracks>;

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
