#pragma once

#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "PV_Definitions.cuh"
#include "VertexDefinitions.cuh"

namespace TrackMVALines {

  // One track parameters.
  const float maxChi2Ndof = 10000.0; // Large for now until we better understand the parameterized Kalman fit quality.
  const float minPt = 1000.0;
  const float maxPt = 25000.0;
  const float minIPChi2 = 7.4;
  const float param1 = 1.0;
  const float param2 = 1.0;
  const float param3 = 1.1;
  const float alpha = 2000.0;

  // Two track parameters.
  const float minComboPt = 2000.0;
  const float maxVertexChi2 = 10.0;
  const float minMCor = 1000.0;
  const float minEta = 2.0;
  const float maxEta = 5.0;
  const int maxNTrksAssoc = 2; // Placeholder. To be replaced with MVA selection.
  const float minFDChi2 = 0.0; // Placeholder. To be replaced with MVA selection.

  // Selections.
  __device__ bool OneTrackMVA(const ParKalmanFilter::FittedTrack& track);
  __device__ bool TwoTrackMVA(const VertexFit::TrackMVAVertex& vertex);  
}
