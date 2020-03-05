#pragma once

#include "VeloEventModel.cuh"
#include <cassert>

__device__ void process_modules(
  Velo::Module* module_data,
  bool* hit_used,
  const short* h0_candidates,
  const short* h2_candidates,
  const uint* module_hitStarts,
  const uint* module_hitNums,
  Velo::ConstClusters& velo_cluster_container,
  const half_t* hit_phi,
  uint* tracks_to_follow,
  Velo::TrackletHits* weak_tracks,
  Velo::TrackletHits* tracklets,
  Velo::TrackHits* tracks,
  unsigned short* h1_rel_indices,
  const uint hit_offset,
  const float* dev_velo_module_zs,
  uint* dev_atomics_velo,
  uint* dev_number_of_velo_tracks,
  const int ttf_modulo_mask,
  const float max_scatter_seeding,
  const uint ttf_modulo,
  const float max_scatter_forwarding,
  const uint max_skipped_modules,
  const float forward_phi_tolerance);
