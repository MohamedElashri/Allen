#pragma once

#include "TrackMVALines.cuh"
#include "MuonLines.cuh"
#include <string>


namespace Hlt1 {

  // Number of special lines
  const unsigned int nSpecialLines = 1;
  const unsigned int nOneTrackLines = 2;
  const unsigned int nTwoTrackLines = 4;
  const unsigned int nThreeTrackLines = 0;
  const unsigned int nFourTrackLines = 0;
  const unsigned int startOneTrackLines = nSpecialLines;
  const unsigned int startTwoTrackLines = startOneTrackLines + nOneTrackLines;
  const unsigned int startThreeTrackLines = startTwoTrackLines + nTwoTrackLines;
  const unsigned int startFourTrackLines = startThreeTrackLines + nThreeTrackLines;
  
  // Hlt1 lines.
  enum Hlt1Lines {
    PassThrough,
    // Begin 1-track lines.
    OneTrackMVA,
    SingleMuon,
    // Begin 2-track lines.
    TwoTrackMVA,
    DisplacedDiMuon,
    HighMassDiMuon,
    SoftDiMuon,
    // Begin 3-track lines.
    // Begin 4-track lines.
    End
  };

  // Hlt1 line names.
  static const std::string Hlt1LineNames[] = {
    "PassThrough",
    // Begin 1-track lines.
    "OneTrackMVA",
    "SingleMuon",
    // Begin 2-track lines.
    "TwoTrackMVA",
    "DisplacedDiMuon",
    "HighMassDiMuon",
    "SoftDiMuon"
    // Begin 3-track lines.
    // Begin 4-track lines.
  };

  // See if this works...
  static __device__ bool (*OneTrackSelections[])(const ParKalmanFilter::FittedTrack&) = {
    TrackMVALines::OneTrackMVA,
    MuonLines::SingleMuon
  };

  static __device__ bool (*TwoTrackSelections[])(const VertexFit::TrackMVAVertex&) = {
    TrackMVALines::TwoTrackMVA,
    MuonLines::DisplacedDiMuon,
    MuonLines::HighMassDiMuon,
    MuonLines::DiMuonSoft
  };
  
}