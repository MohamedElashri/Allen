#pragma once

#include <cstdint>
#include <cfloat>
#include "ClusteringDefinitions.cuh"
#include "VeloDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "FillCandidates.cuh"
#include "ProcessModules.cuh"
#include "TrackForwarding.cuh"
#include "TrackSeeding.cuh"
#include "WeakTracksAdder.cuh"
#include "GpuAlgorithm.cuh"
#include "ArgumentsVelo.cuh"

__global__ void velo_search_by_triplet(
  uint32_t* dev_velo_cluster_container,
  uint* dev_module_cluster_start,
  uint* dev_module_cluster_num,
  Velo::TrackHits* dev_tracks,
  Velo::TrackletHits* dev_tracklets,
  uint* dev_tracks_to_follow,
  Velo::TrackletHits* dev_weak_tracks,
  bool* dev_hit_used,
  uint* dev_atomics_velo,
  short* dev_h0_candidates,
  short* dev_h2_candidates,
  unsigned short* dev_rel_indices,
  const VeloGeometry* dev_velo_geometry);

struct velo_search_by_triplet_t : public GpuAlgorithm {
  constexpr static auto name {"velo_search_by_triplet_t"};
  decltype(gpu_function(velo_search_by_triplet)) function {velo_search_by_triplet};
  using Arguments = std::tuple<
    dev_velo_cluster_container,
    dev_estimated_input_size,
    dev_module_cluster_num,
    dev_tracks,
    dev_tracklets,
    dev_tracks_to_follow,
    dev_weak_tracks,
    dev_hit_used,
    dev_atomics_velo,
    dev_h0_candidates,
    dev_h2_candidates,
    dev_rel_indices>;

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
  Property<float> m_tol {this,
                         "forward_phi_tolerance",
                         Configuration::velo_search_by_triplet_t::forward_phi_tolerance,
                         0.052f,
                         "tolerance"};
  Property<float> m_chi2 {this, "max_chi2", Configuration::velo_search_by_triplet_t::max_chi2, 20.0f, "chi2"};
  Property<float> m_scat {this,
                          "max_scatter_forwarding",
                          Configuration::velo_search_by_triplet_t::max_scatter_forwarding,
                          0.1f,
                          "scatter forwarding"};
  Property<float> m_seed {this,
                          "max_scatter_seeding",
                          Configuration::velo_search_by_triplet_t::max_scatter_seeding,
                          0.1f,
                          "scatter seeding"};
  Property<uint> m_skip {this,
                         "max_skipped_modules",
                         Configuration::velo_search_by_triplet_t::max_skipped_modules,
                         1u,
                         "skipped modules"};
  Property<uint> m_max_weak {this,
                             "max_weak_tracks",
                             Configuration::velo_search_by_triplet_t::max_weak_tracks,
                             500u,
                             "max weak tracks"};
  Property<float> m_ext_base {this,
                              "phi_extrapolation_base",
                              Configuration::velo_search_by_triplet_t::phi_extrapolation_base,
                              0.03f,
                              "phi extrapolation base"};
  Property<float> m_ext_coef {this,
                              "phi_extrapolation_coef",
                              Configuration::velo_search_by_triplet_t::phi_extrapolation_coef,
                              0.0002f,
                              "phi extrapolation coefficient"};
  Property<uint> m_ttf_mod {this,
                            "ttf_modulo",
                            Configuration::velo_search_by_triplet_t::ttf_modulo,
                            2048u,
                            "ttf modulo"};
  Property<int> m_ttf_mask {this,
                            "ttf_modulo_mask",
                            Configuration::velo_search_by_triplet_t::ttf_modulo_mask,
                            0x7FF,
                            "ttf modulo mask"};
};
