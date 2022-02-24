/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <vector>
#include <array>
#include <functional>

#include <Event/RawBank.h>

#include "Common.h"
#include "Logger.h"
#include "SystemOfUnits.h"
#include "AllenUnits.h"
#include "BankTypes.h"

namespace {
  using namespace Allen::Units;
} // namespace

namespace LHCb {
  constexpr auto NBankTypes = LHCb::RawBank::types().size();
} // namespace LHCb

namespace Allen {

  // There are at most 550 Tell40s in the system (2 fragments per
  // Tell40) plus a conservative estimate of 100 banks for Allen MC
  // info (tracks and vertices each)
  constexpr size_t max_fragments = 1300;

  // Read buffer containing the number of events, offsets to the start
  // of the event and the event data
  using ReadBuffer = std::tuple<size_t, std::vector<unsigned int>, std::vector<char>, size_t>;
  using ReadBuffers = std::vector<ReadBuffer>;

  struct Slice {
    std::vector<gsl::span<char>> fragments;
    std::vector<gsl::span<uint16_t>> sizes;
    size_t fragments_mem_size = 0;
    gsl::span<unsigned int> offsets;
    size_t n_offsets;
  };

  using BankSlices = std::vector<Slice>;
  using Slices = std::array<BankSlices, NBankTypes>;

  std::array<int, LHCb::NBankTypes> bank_ids();

  using sd_from_raw_bank = std::function<BankTypes(LHCb::RawBank const* raw_bank)>;
  using bank_sorter = std::function<bool(LHCb::RawBank const* a, LHCb::RawBank const* b)>;

} // namespace Allen
