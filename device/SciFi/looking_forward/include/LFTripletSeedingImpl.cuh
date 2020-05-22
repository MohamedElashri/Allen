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
  const unsigned layer_0,
  const unsigned layer_1,
  const unsigned layer_2,
  const int l0_size,
  const int l1_size,
  const int l2_size,
  const float z0,
  const float z1,
  const float z2,
  const int* initial_windows,
  const unsigned ut_total_number_of_tracks,
  const float qop,
  const float ut_tx,
  const float velo_tx,
  const float x_at_z_magnet,
  float* shared_x1,
  int* scifi_lf_found_triplets,
  int8_t* scifi_lf_number_of_found_triplets,
  const unsigned triplet_seed);
