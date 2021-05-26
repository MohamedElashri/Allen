/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once
#include <sys/stat.h>
#include <fcntl.h>

#include <cstdio>
#include <iostream>
#include <fstream>
#include <vector>
#include <unordered_map>
#include <unordered_set>
#include <functional>

#include <BankTypes.h>
#include <BankMapping.h>
#include <AllenIO.h>

#include <gsl/gsl>

#include <sys/types.h>

#include "Event/ODIN.h"
#include "Event/RawBank.h"
#include "mdf_header.hpp"

namespace {
  constexpr auto mdf_header_size = sizeof(LHCb::MDFHeader);
  constexpr auto bank_header_size = 4 * sizeof(short);
} // namespace

namespace Allen {
  using buffer_map = std::unordered_map<BankTypes, std::pair<std::vector<char>, std::vector<unsigned int>>>;
} // namespace Allen

namespace MDF {

  Allen::IO open(std::string const& filepath, int flags, int mode = 0);

  void dump_hex(const char* start, int size);

  std::tuple<bool, bool, gsl::span<char>> read_event(
    Allen::IO& input,
    LHCb::MDFHeader& h,
    gsl::span<char> buffer,
    std::vector<char>& decompression_buffer,
    bool checkChecksum = true,
    bool dbg = false);

  std::tuple<bool, bool, gsl::span<char>> read_banks(
    Allen::IO& input,
    const LHCb::MDFHeader& h,
    gsl::span<char> buffer,
    std::vector<char>& decompression_buffer,
    bool checkChecksum = true,
    bool dbg = false);

  std::tuple<size_t, Allen::buffer_map, std::vector<LHCb::ODIN>> read_events(
    size_t n,
    const std::vector<std::string>& files,
    const std::unordered_set<BankTypes>& types,
    bool checkChecksum = true,
    size_t offset = 0);

  LHCb::ODIN decode_odin(unsigned int version, unsigned int const* odinData);

} // namespace MDF
