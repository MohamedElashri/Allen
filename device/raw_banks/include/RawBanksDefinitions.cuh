#pragma once

#include "ParKalmanDefinitions.cuh"
#include <string>

namespace Hlt1 {
  // Hlt1 TCK.
  constexpr static unsigned int TCK = 0x00000000;

  // Task ID.
  constexpr static unsigned int taskID = 1;

  // 1 StdInfo per passed decision.
  constexpr static unsigned int nStdInfoDecision = 1;

  // 6 per passing track.
  constexpr static unsigned int nStdInfoTrack = 6;

  // 3 per passing secondary vertex.
  constexpr static unsigned int nStdInfoSV = 3;

  // Maximum number of StdInfo to store. Indices are 8 bits.
  constexpr static unsigned int maxStdInfoEvent = 256;

  // Default allocation size.
  constexpr static unsigned int subStrDefaultAllocationSize = 500;

  // Maximum number of candidates per line.
  // For now just make this equal for every line.
  constexpr static unsigned int maxCandidates = 1000;

  // Maximum numbers of candidates per event.
  constexpr static unsigned int nMaxOneTrackMVA = 1000;
  constexpr static unsigned int nMaxTwoTrackMVA = 1000;
  constexpr static unsigned int nMaxSingleMuon = 1000;
  constexpr static unsigned int nMaxDisplacedDiMuon = 1000;
  constexpr static unsigned int nMaxHighMassDiMuon = 1000;

  // CLIDs.
  // TODO: Save these in the classes themselves.
  constexpr static unsigned int nObjTyp = 3;
  constexpr static unsigned int selectionCLID = 1;
  constexpr static unsigned int trackCLID = 10010;
  constexpr static unsigned int svCLID = 10030;

  constexpr static unsigned int number_of_sel_atomics = 3;
  namespace atomics {
    enum atomic_types {
      // n_passing_decisions,
      n_svs_saved,
      n_tracks_saved,
      n_hits_saved
    };
  }
} // namespace Hlt1
