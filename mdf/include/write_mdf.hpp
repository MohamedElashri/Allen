/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <gsl/gsl>

namespace Allen {
  constexpr int mdf_header_version = 3;
  constexpr unsigned bank_alignment = sizeof(unsigned);

  inline size_t padded_bank_size(size_t const bank_size)
  {
    return bank_size + (bank_alignment - (bank_size % bank_alignment)) % bank_alignment;
  }

  size_t add_raw_bank(
    unsigned char const type,
    unsigned char const version,
    short const sourceID,
    gsl::span<char const> fragment,
    char* buffer);
} // namespace Allen
