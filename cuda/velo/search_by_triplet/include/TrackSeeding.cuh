#pragma once

#include "VeloEventModel.cuh"

__device__ void track_seeding(
  const float* dev_velo_cluster_container,
  const uint number_of_hits,
  const Velo::Module* module_data,
  const short* h0_candidates,
  const short* h2_candidates,
  bool* hit_used,
  Velo::TrackletHits* tracklets,
  uint* tracks_to_follow,
  unsigned short* h1_rel_indices,
  uint* dev_shifted_atomics_velo);
