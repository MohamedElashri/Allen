#pragma once

#include <vector>

#include <gsl-lite.hpp>

#include "eb_header.hpp"
#include "mdf_header.hpp"

namespace MEP {
  std::tuple<bool, EB::Header, gsl::span<char const>>
  read_mep(int fd, std::vector<char>& buffer);
}
