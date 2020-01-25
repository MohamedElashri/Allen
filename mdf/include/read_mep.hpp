#pragma once

#include <vector>

#include <gsl-lite.hpp>

#include "eb_header.hpp"
#include "mdf_header.hpp"
#include "read_mdf.hpp"

namespace MEP {
  std::tuple<bool, bool, EB::Header, gsl::span<char const>> read_mep(Allen::IO& input, std::vector<char>& buffer);
}
