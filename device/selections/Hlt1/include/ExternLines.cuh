#pragma once

#include "BackendCommon.h"

namespace track_mva_line {
  struct track_mva_line_t;
  struct Parameters;
}

namespace kstopipi_line {
  struct kstopipi_line_t;
  struct Parameters;
}

extern template __device__ void process_line<track_mva_line::track_mva_line_t, track_mva_line::Parameters>(char*);
extern template __device__ void process_line<kstopipi_line::kstopipi_line_t, kstopipi_line::Parameters>(char*);

constexpr auto line_strings = {"track_mva_line_t", "kstopipi_line_t"};

constexpr std::array<void(*)(char*), 2> line_functions = {
  process_line<track_mva_line::track_mva_line_t, track_mva_line::Parameters>,
  process_line<kstopipi_line::kstopipi_line_t, kstopipi_line::Parameters>
};
