#pragma once

#include "ParKalmanDefinitions.cuh"
#include "ParKalmanMath.cuh"
#include "VertexDefinitions.cuh"
#include "SystemOfUnits.h"

namespace MuonLines {
  // Track quality.
  const float maxChi2Ndof = 10000.f; // Large until we better understand the parameterized Kalman fit quality.

  // Vertex quality.
  const float maxVertexChi2 = 8.f;
  
  // Single muon selections.
  const float singleMinPt = 10000.f / Gaudi::Units::MeV;

  // Dimuon track pt.
  const float minTrackPt = 500.f / Gaudi::Units::MeV;

  // Displaced dimuon selections.
  const float dispMinIPChi2 = 6.f;
  const float dispMinEta = 2.f;
  const float dispMaxEta = 5.f;

  // High mass dimuon (J/Psi).
  const float minMass = 2700.f / Gaudi::Units::MeV;

  // Selection functions.
  __device__ bool SingleMuon(const ParKalmanFilter::FittedTrack& track);
  __device__ bool DisplacedDiMuon(const VertexFit::TrackMVAVertex& vertex);
  __device__ bool HighMassDiMuon(const VertexFit::TrackMVAVertex& vertex);
}
