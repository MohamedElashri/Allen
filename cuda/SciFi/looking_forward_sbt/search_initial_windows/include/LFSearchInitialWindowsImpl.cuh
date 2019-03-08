#pragma once

#include <cmath>
#include <array>
#include <vector>
#include <algorithm>
#include <fstream>
#include "SciFiDefinitions.cuh"
#include "PrForwardConstants.cuh"
#include "UTDefinitions.cuh"
#include "TrackUtils.cuh"
#include "HitUtils.cuh"
#include "LinearFitting.cuh"
#include "ReferencePlaneProjection.cuh"
#include "PrVeloUT.cuh"
#include "SciFiEventModel.cuh"

__host__ __device__ inline float evalCubicParameterization(
  const float value_at_ref,
  const float t,
  const float z);

__host__ __device__ void lf_search_initial_windows_impl(
  const SciFi::Hits& scifi_hits,
  const SciFi::HitCount& scifi_hit_count,
  const float xAtRef,
  const float yAtRef,
  const MiniState& velo_state,
  const SciFi::Tracking::Arrays* constArrays,
  const float qOverP,
  const int side,
  int* initial_windows,
  const int number_of_tracks);
