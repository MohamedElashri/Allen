#pragma once

#include "Common.h"
#include "LookingForwardConstants.h"
#include "SciFiEventModel.cuh"
#include "TrackUtils.cuh"

 inline float evalCubicParameterization(const float params[4], float z);


int fitParabola_proto(
  const SciFi::Hits& scifi_hits,
  const int* coordToFit,
  const int n_coordToFit,
  float trackParameters[SciFi::Tracking::nTrackParams],
  const bool xFit);

float get_average_x_at_reference_plane(
  std::vector<int> x_hits,
  const SciFi::Hits& scifi_hits,
  const float xParams_seed[4],
  const SciFi::Tracking::Arrays* constArrays,
  const MiniState velo_state,
  const float zMagSlope);

int getChi2( 
  const SciFi::Hits& scifi_hits,
  int* coordToFit,
  const int n_coordToFit,
  float trackParameters[SciFi::Tracking::nTrackParams],
  const bool xFit);

bool fitYProjection_proto(
  MiniState velo_state,
  const SciFi::Tracking::Arrays* constArrays,
  const std::vector<int>& uv_hits,
  const SciFi::Hits& scifi_hits,
  float trackParams[SciFi::Tracking::nTrackParams]);
