#pragma once

#include "Common.h"
#include "LookingForwardConstants.h"
#include "SciFiEventModel.cuh"
#include "TrackUtils.cuh"

 inline float evalCubicParameterization(const float params[4], float z);

int fitParabola(
  SciFi::TrackHits& track,
  const SciFi::Hits& scifi_hits,
  const int event_offset,
  float trackParameters[SciFi::Tracking::nTrackParams]);

bool quadraticFitX(
  const SciFi::Hits& scifi_hits,
  const int event_offset,
  float trackParameters[SciFi::Tracking::nTrackParams],
  SciFi::TrackHits& track);

float get_average_x_at_reference_plane(
  std::vector<int> x_hits,
  const SciFi::Hits& scifi_hits,
  const float xParams_seed[4],
  const SciFi::Tracking::Arrays* constArrays,
  const MiniState velo_state,
  const float zMagSlope);
