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

  // Read buffer containing the number of events, offsets to the start
  // of the event and the event data
  using ReadBuffer = std::tuple<size_t, std::vector<unsigned int>, std::vector<char>, size_t>;
  using ReadBuffers = std::vector<ReadBuffer>;

  // A slice contains transposed bank data, offsets to the start of each
  // set of banks and the number of sets of banks
  using Slice = std::tuple<std::vector<gsl::span<char>>, size_t, gsl::span<unsigned int>, size_t>;
  using BankSlices = std::vector<Slice>;
  using Slices = std::array<BankSlices, NBankTypes>;

  std::array<int, LHCb::NBankTypes> bank_ids();
  int subdetector_id(const std::string subdetector);
  int subdetector_index(const std::string subdetector);
  int subdetector_index_from_bank_type(BankTypes bt);

  using sd_from_raw_bank = std::function<BankTypes(LHCb::RawBank const* raw_bank)>;
  using bank_sorter = std::function<bool(LHCb::RawBank const* a, LHCb::RawBank const* b)>;

} // namespace Allen
