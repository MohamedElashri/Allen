#pragma once

#include <cstdint>
#include <cfloat>
#include "ClusteringDefinitions.cuh"
#include "VeloEventModel.cuh"
#include "FillCandidates.cuh"
#include "ProcessModules.cuh"
#include "TrackForwarding.cuh"
#include "TrackSeeding.cuh"
#include "WeakTracksAdder.cuh"
#include "Handler.cuh"
#include "ArgumentsVelo.cuh"

__global__ void search_by_triplet(
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

namespace Configuration {
  namespace velo_search_by_triplet_t {
    // Forward tolerance in phi
    extern __constant__ float forward_phi_tolerance;

    // Max chi2
    extern __constant__ float max_chi2;

    // Max scatter for forming triplets (seeding) and forwarding
    extern __constant__ float max_scatter_forwarding;
    extern __constant__ float max_scatter_seeding;

    // Maximum number of skipped modules allowed for a track
    // before storing it
    extern __constant__ uint max_skipped_modules;

    // Maximum number of tracks to follow at a time
    extern __constant__ uint max_weak_tracks;

    // These parameters impact the found tracks
    // Maximum / minimum acceptable phi
    // These two parameters impacts enourmously the speed of track seeding
    extern __constant__ float phi_extrapolation_base;
    // A higher coefficient improves efficiency at the
    // cost of performance
    extern __constant__ float phi_extrapolation_coef;

    // Maximum number of tracks to follow at a time
    extern __constant__ uint ttf_modulo;
    extern __constant__ int ttf_modulo_mask;
  } // namespace velo_search_by_triplet_t
} // namespace Configuration

ALGORITHM(search_by_triplet,
          velo_search_by_triplet_t,
          ARGUMENTS(
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
            dev_rel_indices),
          Allen::Property<float> m_tol {this,
                                 "forward_phi_tolerance",
                                 Configuration::velo_search_by_triplet_t::forward_phi_tolerance,
                                 0.052f,
                                 "tolerance"};
          Allen::Property<float> m_chi2 {this, "max_chi2", Configuration::velo_search_by_triplet_t::max_chi2, 20.0f, "chi2"};
          Allen::Property<float> m_scat {this,
                                  "max_scatter_forwarding",
                                  Configuration::velo_search_by_triplet_t::max_scatter_forwarding,
                                  0.1f,
                                  "scatter forwarding"};
          Allen::Property<float> m_seed {this,
                                  "max_scatter_seeding",
                                  Configuration::velo_search_by_triplet_t::max_scatter_seeding,
                                  0.1f,
                                  "scatter seeding"};
          Allen::Property<uint> m_skip {this,
                                 "max_skipped_modules",
                                 Configuration::velo_search_by_triplet_t::max_skipped_modules,
                                 1u,
                                 "skipped modules"};
          Allen::Property<uint> m_max_weak {this,
                                     "max_weak_tracks",
                                     Configuration::velo_search_by_triplet_t::max_weak_tracks,
                                     500u,
                                     "max weak tracks"};
          Allen::Property<float> m_ext_base {this,
                                      "phi_extrapolation_base",
                                      Configuration::velo_search_by_triplet_t::phi_extrapolation_base,
                                      0.03f,
                                      "phi extrapolation base"};
          Allen::Property<float> m_ext_coef {this,
                                      "phi_extrapolation_coef",
                                      Configuration::velo_search_by_triplet_t::phi_extrapolation_coef,
                                      0.0002f,
                                      "phi extrapolation coefficient"};
          Allen::Property<uint>
            m_ttf_mod {this, "ttf_modulo", Configuration::velo_search_by_triplet_t::ttf_modulo, 2048u, "ttf modulo"};
          Allen::Property<int> m_ttf_mask {this,
                                    "ttf_modulo_mask",
                                    Configuration::velo_search_by_triplet_t::ttf_modulo_mask,
                                    0x7FF,
                                    "ttf modulo mask"};)
