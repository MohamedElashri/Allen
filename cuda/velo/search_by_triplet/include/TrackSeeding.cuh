#pragma once

#include "VeloEventModel.cuh"

__device__ void track_seeding(
  Velo::ConstClusters& velo_cluster_container,
  const Velo::Module* module_data,
  bool* hit_used,
  Velo::TrackletHits* tracklets,
  uint* tracks_to_follow,
  unsigned short* h1_rel_indices,
  uint* dev_shifted_atomics_velo,
  const float max_scatter_seeding,
  const uint max_tracks_to_follow,
  const float* hit_phi);
