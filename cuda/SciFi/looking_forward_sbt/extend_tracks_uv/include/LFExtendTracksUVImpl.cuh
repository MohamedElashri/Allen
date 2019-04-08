#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"

__device__ void lf_extend_tracks_uv_impl(
  const float* scifi_hits_x0,
  const short layer_offset,
  const short layer_number_of_hits,
  SciFi::TrackHits& track,
  const float x0,
  const float x1,
  const float z0,
  const float z1,
  const float z2,
  const float projection_y_zone_dxdy,
  const float max_chi2);
