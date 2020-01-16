#pragma once
#include <string>

namespace Hlt1 {

  // Hlt1 TCK.
  const unsigned int TCK = 0x00002001;

  // Task ID.
  const unsigned int taskID = 1;

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
    OneTrackMVA,
    SingleMuon,
    TwoTrackMVA,
    DisplacedDiMuon,
    HighMassDiMuon,
    SoftDiMuon,
    End
  };

  // Hlt1 line names.
  static const std::string Hlt1LineNames[] = {
    "PassThrough",
    "OneTrackMVA",
    "SingleMuon",
    "TwoTrackMVA",
    "DisplacedDiMuon",
    "HighMassDiMuon",
    "SoftDiMuon"
  };
  
}
