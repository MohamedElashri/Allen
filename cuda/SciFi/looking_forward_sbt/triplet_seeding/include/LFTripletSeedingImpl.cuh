#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "UTDefinitions.cuh"
#include "LookingForwardConstants.cuh"

__device__ void lf_triplet_seeding_impl(
  const float* scifi_hits_x0,
  const uint8_t h0_candidate_size,
  const uint8_t h1_candidate_size,
  const uint8_t h2_candidate_size,
  const uint8_t relative_l0,
  const uint8_t relative_l1,
  const uint8_t relative_l2,
  const float max_chi2,
  float* best_chi2,
  int8_t* best_h0_h2,
  const short* scifi_lf_candidates,
  const float z0,
  const float z1,
  const float z2,
  const float qop);
