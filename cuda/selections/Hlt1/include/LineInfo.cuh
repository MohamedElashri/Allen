#pragma once

namespace Hlt1 {
  // Types of lines
  struct Line {};

  struct SpecialLine : Line {
    constexpr static auto scale_factor = 1.f;
  };
  struct OneTrackLine : Line {
    constexpr static auto scale_factor = 1.f;
  };
  struct TwoTrackLine : Line {
    constexpr static auto scale_factor = 1.f;
  };
  struct ThreeTrackLine : Line {
    constexpr static auto scale_factor = 1.f;
  };
  struct FourTrackLine : Line {
    constexpr static auto scale_factor = 1.f;
  };
} // namespace Hlt1
