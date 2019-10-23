#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "SciFiEventModel.cuh"
#include "Handler.cuh"
#include "ArgumentsSciFi.cuh"
#include "ArgumentsUT.cuh"
#include "ArgumentsVelo.cuh"
#include "UTConsolidated.cuh"
#include "TrackUtils.cuh"
#include "LFFit.cuh"

__global__ void lf_quality_filter_collected_hits(
  const uint* dev_atomics_ut,
  const SciFi::TrackHits* dev_scifi_lf_tracks,
  const uint* dev_scifi_lf_atomics,
  uint* dev_scifi_lf_collected_hits_atomics,
  uint* dev_scifi_lf_collected_hits_tracks);

ALGORITHM(
  lf_quality_filter_collected_hits,
  lf_quality_filter_collected_hits_t,
  ARGUMENTS(
    dev_atomics_ut,
    dev_scifi_lf_tracks,
    dev_scifi_lf_atomics,
    dev_scifi_lf_collected_hits_atomics,
    dev_scifi_lf_collected_hits_tracks))
