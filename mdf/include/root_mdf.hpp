#pragma once

#include <ROOTHeaders.h>

#include "read_mdf.hpp"

namespace MDF {
  namespace ROOT {
    Allen::IO open(std::string const& filepath, int flags);
    bool close(TFile* f);
    ssize_t read(TFile* f, char* ptr, size_t size);
    ssize_t write(TFile* f, char const* ptr, size_t size);
  } // namespace ROOT
} // namespace MDF
