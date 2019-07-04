#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "UTDefinitions.cuh"
#include "LookingForwardConstants.cuh"

__device__ void lf_triplet_seeding_choose_best_triplets_for_h1(
  const float* scifi_hits_x0,
  const short* scifi_lf_candidates,
  const uint8_t triplet_seed,
  const float zdiff,
  const float* shared_partial_chi2,
  const float extrap1,
  const int h1_candidate_size,
  const int8_t h0_tile_index,
  const int8_t h2_tile_index,
  const float max_chi2,
  const LookingForward::Constants* dev_looking_forward_constants,
  float* best_chi2,
  int8_t* best_h0_h2);

__device__ void lf_triplet_seeding_impl(
  const float* scifi_hits_x0,
  const uint8_t h0_candidate_size,
  const uint8_t h1_candidate_size,
  const uint8_t h2_candidate_size,
  const uint8_t triplet_seed,
  const float max_chi2,
  const LookingForward::Constants* dev_looking_forward_constants,
  float* best_chi2,
  int8_t* best_h0_h2,
  const short* scifi_lf_candidates,
  const float dz1,
  const float dz2,
  const float qop);
