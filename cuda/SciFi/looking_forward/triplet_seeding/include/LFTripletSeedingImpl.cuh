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
  const float z0,
  const float z1,
  const float z2,
  const int l0_start,
  const int l1_start,
  const int l2_start,
  const int l0_size,
  const int l1_size,
  const int l2_size,
  const int central_window_l0_begin,
  const int central_window_l1_begin,
  const int central_window_l2_begin,
  const int* initial_windows,
  const uint ut_total_number_of_tracks,
  const float qop,
  const float ut_tx,
  const float velo_tx,
  const float x_at_z_magnet,
  float* shared_x1,
  float* scifi_lf_triplet_best);
