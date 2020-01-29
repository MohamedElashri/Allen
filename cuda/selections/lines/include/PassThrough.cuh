#pragma once

#include "LineInfo.cuh"

namespace PassThrough {
  struct PassThrough_t : public Hlt1::SpecialLine {
    constexpr static auto name {"PassThrough"};
  };
} // namespace DiMuonSoft
