#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "UTDefinitions.cuh"
#include "LookingForwardConstants.cuh"

__device__ void lf_triplet_seeding_impl(
  const SciFi::Hits& scifi_hits,
  const uint h0_candidate_offset,
  const uint h1_candidate_offset,
  const uint h2_candidate_offset,
  const uint8_t h0_candidate_size,
  const uint8_t h1_candidate_size,
  const uint8_t h2_candidate_size,
  const uint8_t relative_middle_layer,
  const short* dev_scifi_lf_candidates,
  const float max_chi2,
  float* best_chi2,
  int8_t* best_h0_h2,
  const uint event_offset);
