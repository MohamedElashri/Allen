#pragma once

#include <functional>
#include <tuple>
#include <utility>
#include <cstdio>
#include <string>
#include "VertexDefinitions.cuh"

namespace Hlt1 {
  // Types of lines
  struct Line {
  };

  struct SpecialLine : Line {
  };
  struct OneTrackLine : Line {
  };
  struct TwoTrackLine : Line {
  };
  struct ThreeTrackLine : Line {
  };
  struct FourTrackLine : Line {
  };

  // Deprecated
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
} // namespace Hlt1