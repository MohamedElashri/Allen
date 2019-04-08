#pragma once

#include "SciFiDefinitions.cuh"
#include "SciFiEventModel.cuh"
#include "UTDefinitions.cuh"
#include "LookingForwardConstants.cuh"

__device__ void lf_find_compatible_windows_impl(
  const SciFi::Hits& scifi_hits,
  const uint8_t relative_layer,
  const uint* number_of_candidates,
  const short* candidates,
  const LookingForward::Constants* dev_looking_forward_constants,
  const float UT_state_tx,
  const float x_at_ref,
  const float z_mag,
  const int ut_total_number_of_tracks,
  short* compatible_window,
  const int total_number_of_candidates,
  const float event_offset);
