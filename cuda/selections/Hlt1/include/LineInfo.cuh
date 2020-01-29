#pragma once

namespace Hlt1 {
  // Types of lines
  struct Line {};

  struct SpecialLine : Line {};
  struct OneTrackLine : Line {};
  struct TwoTrackLine : Line {};
  struct ThreeTrackLine : Line {};
  struct FourTrackLine : Line {};
} // namespace Hlt1