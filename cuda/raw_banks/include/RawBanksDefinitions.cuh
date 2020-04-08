#pragma once

#include "ParKalmanDefinitions.cuh"
#include <string>

namespace Hlt1 {
  // Hlt1 TCK.
  const unsigned int TCK = 0x00000000;

  // Task ID.
  const unsigned int taskID = 1;

  // 1 StdInfo per passed decision.
  const unsigned int nStdInfoDecision = 1;

  // 6 per passing track.
  const unsigned int nStdInfoTrack = 6;

  // 3 per passing secondary vertex.
  const unsigned int nStdInfoSV = 3;

  // Maximum number of StdInfo to store. Indices are 8 bits.
  const unsigned int maxStdInfoEvent = 256;

  // Default allocation size.
  const unsigned int subStrDefaultAllocationSize = 500;

  // Maximum number of candidates per line.
  // For now just make this equal for every line.
  const unsigned int maxCandidates = 1000;

  // Maximum numbers of candidates per event.
  const unsigned int nMaxOneTrackMVA = 1000;
  const unsigned int nMaxTwoTrackMVA = 1000;
  const unsigned int nMaxSingleMuon = 1000;
  const unsigned int nMaxDisplacedDiMuon = 1000;
  const unsigned int nMaxHighMassDiMuon = 1000;

  // CLIDs.
  // TODO: Save these in the classes themselves.
  const unsigned int nObjTyp = 3;
  const unsigned int selectionCLID = 1;
  const unsigned int trackCLID = 10010;
  const unsigned int svCLID = 10030;
  
} // namespace Hlt1
