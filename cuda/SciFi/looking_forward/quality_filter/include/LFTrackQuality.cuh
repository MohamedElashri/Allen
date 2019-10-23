#pragma once

#include "LookingForwardConstants.cuh"
#include "LookingForwardTools.cuh"
#include "SciFiEventModel.cuh"
#include "TMVA_Forward.cuh"
#include "TMVA_Forward_1.cuh"
#include "TMVA_Forward_2.cuh"
#include "TrackUtils.cuh"

__device__ float lf_track_quality(
  const SciFi::TrackHits& track,
  const MiniState& velo_state,
  const float VeloUT_qOverP,
  const float* trackParams,
  const SciFi::Tracking::Arrays* constArrays,
  const float magnet_polarity,
  const SciFi::Tracking::TMVA* tmva1);
