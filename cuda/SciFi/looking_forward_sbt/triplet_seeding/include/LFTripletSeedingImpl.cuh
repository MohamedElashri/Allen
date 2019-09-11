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
  const uint8_t layer_0,
  const uint8_t layer_1,
  const uint8_t layer_2,
  SciFi::CombinedValue* best_combined,
  const short* scifi_lf_candidates,
  const float dz1,
  const float dz2,
  const float qop,
  float* shared_partial_chi2);
