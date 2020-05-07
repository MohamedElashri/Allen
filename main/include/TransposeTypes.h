#pragma once

#include <vector>
#include <array>

#include <Common.h>
#include <Logger.h>
#include <SystemOfUnits.h>
#include <Event/RawBank.h>
#include <mdf_header.hpp>
#include <AllenUnits.h>

#ifndef NO_CUDA
#include <CudaCommon.h>
#endif

namespace {
  constexpr auto mdf_header_size = sizeof(LHCb::MDFHeader);
  constexpr auto bank_header_size = 4 * sizeof(short);

  using namespace Allen::Units;
} // namespace

namespace LHCb {
  constexpr auto NBankTypes = to_integral<LHCb::RawBank::BankType>(LHCb::RawBank::LastType);
} // namespace LHCb

// Read buffer containing the number of events, offsets to the start
// of the event and the event data
using ReadBuffer = std::tuple<size_t, std::vector<unsigned int>, std::vector<char>, size_t>;
using ReadBuffers = std::vector<ReadBuffer>;

// A slice contains transposed bank data, offsets to the start of each
// set of banks and the number of sets of banks
using Slice = std::tuple<std::vector<gsl::span<char>>, size_t, gsl::span<unsigned int>, size_t>;
using BankSlices = std::vector<Slice>;
using Slices = std::array<BankSlices, NBankTypes>;

std::vector<int> bank_ids();
