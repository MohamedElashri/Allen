#pragma once

#include <mma.h>
#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "UTDefinitions.cuh"
#include "LookingForwardConstants.cuh"

__device__ void lf_triplet_seeding_impl(
  const SciFi::Hits& scifi_hits,
  const uint candidate_h0_offset,
  const uint candidate_h1_offset,
  const uint candidate_h2_offset,
  uint8_t h0_candidate_size,
  uint8_t h1_candidate_size,
  uint8_t h2_candidate_size,
  const uint8_t relative_middle_layer,
  const float max_chi2,
  float* best_chi2,
  int8_t* best_h0_h2,
  const short* candidates,
  const bool* candidates_flag,
  short* shared_candidates,
  int* atomics_seeding,
  const float z0,
  const float z1,
  const float z2,
  const float qop,
  const int event_offset);
