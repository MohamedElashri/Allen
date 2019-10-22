#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "UTDefinitions.cuh"
#include "LookingForwardConstants.cuh"
#include "CudaCommon.h"

struct CombinedTripletValue {
  float chi2 = LookingForward::chi2_max_triplet_single * LookingForward::chi2_max_triplet_single;
  int16_t h0 = -1;
  int16_t h1 = -1;
  int16_t h2 = -1;
};

__device__ void lf_triplet_seeding_impl(
  const float* scifi_hits_x0,
  const uint layer_0,
  const uint layer_1,
  const uint layer_2,
  const int l0_start,
  const int l1_start,
  const int l2_start,
  const int l0_extrapolated,
  const int l1_extrapolated,
  const int l2_extrapolated,
  const int l0_size,
  const int l1_size,
  const int l2_size,
  const float z0,
  const float z1,
  const float z2,
  const float qop,
  const MiniState* ut_state,
  float* shared_partial_chi2,
  SciFi::TrackHits* scifi_tracks,
  uint* atomics_scifi,
  const LookingForward::Constants* dev_looking_forward_constants,
  const uint number_of_ut_track,
  const uint number_of_seeds,
  const MiniState& velo_state);
