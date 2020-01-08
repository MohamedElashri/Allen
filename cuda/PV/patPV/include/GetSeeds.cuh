#pragma once

#include "VeloDefinitions.cuh"
#include "patPV_Definitions.cuh"
#include <stdint.h>
#include "VeloEventModel.cuh"
#include "Common.h"
#include "DeviceAlgorithm.cuh"
#include "ArgumentsVelo.cuh"
#include "ArgumentsPV.cuh"
#include "VeloConsolidated.cuh"

__global__ void get_seeds(
  char* dev_velo_kalman_beamline_states,
  uint* dev_atomics_storage,
  uint* dev_velo_track_hit_number,
  PatPV::XYZPoint* dev_seeds,
  uint* dev_number_seeds);

__device__ int find_clusters(PatPV::vtxCluster* vclus, float* zclusters, int number_of_clusters);

struct pv_get_seeds_t : public DeviceAlgorithm {
  constexpr static auto name {"pv_get_seeds_t"};
  decltype(global_function(get_seeds)) function {get_seeds};
  using Arguments = std::tuple<
    dev_velo_kalman_beamline_states, dev_atomics_velo, dev_velo_track_hit_number, dev_seeds, dev_number_seeds>;

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

private:
  Property<float>
    m_chi2 {this, "max_chi2_merge", Configuration::pv_get_seeds_t::max_chi2_merge, 25.f, "max chi2 merge"};
  Property<float> m_ferr {this,
                          "factor_to_increase_errors",
                          Configuration::pv_get_seeds_t::factor_to_increase_errors,
                          15.f,
                          "factor to increase errors"};
  Property<int>
    m_mult {this, "min_cluster_mult", Configuration::pv_get_seeds_t::min_cluster_mult, 4, "min cluster mult"};
  Property<int> m_close {this,
                         "min_close_tracks_in_cluster",
                         Configuration::pv_get_seeds_t::min_close_tracks_in_cluster,
                         3,
                         "min close tracks in cluster"};
  Property<float> m_dz {this,
                        "dz_close_tracks_in_cluster",
                        Configuration::pv_get_seeds_t::dz_close_tracks_in_cluster,
                        5.f,
                        "dz close tracks in cluster [mm]"};
  Property<int> m_himult {this, "high_mult", Configuration::pv_get_seeds_t::high_mult, 10, "high mult"};
  Property<float> m_ratiohi {this,
                             "ratio_sig2_high_mult",
                             Configuration::pv_get_seeds_t::ratio_sig2_high_mult,
                             1.0f,
                             "ratio sig2 high mult"};
  Property<float> m_ratiolo {this,
                             "ratio_sig2_low_mult",
                             Configuration::pv_get_seeds_t::ratio_sig2_low_mult,
                             0.9f,
                             "ratio sig2 low mult"};
};
