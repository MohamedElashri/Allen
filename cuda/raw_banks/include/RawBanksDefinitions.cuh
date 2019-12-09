#pragma once

namespace Hlt1 {

  // Hlt1 TCK.
  const unsigned int TCK = 0x00002001;

  // Task ID.
  const unsigned int taskID = 1;
  
  // Hlt1 lines.
  enum Hlt1Lines {
    PassThrough,
    OneTrackMVA,
    TwoTrackMVA,
    SingleMuon,
    DisplacedDiMuon,
    HighMassDiMuon,
    End
  };
  
}
