#pragma once

namespace Hlt1 {

  // Hlt1 TCK.
  const unsigned int TCK = 0x00002001;

  // Task ID.
  const unsigned int taskID = 1;
  
  // Hlt1 lines.
  enum Hlt1Lines {
    PassThrough,
    StartOneTrackLines, // Flag for start of list of 1-track lines.
    OneTrackMVA,
    SingleMuon,
    StartTwoTrackLines, // Flag for start of list of 2-track lines.
    TwoTrackMVA,
    DisplacedDiMuon,
    HighMassDiMuon,
    SoftDiMuon,
    End
  };
  
}
