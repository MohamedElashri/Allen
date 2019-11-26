#pragma once

#include <cstdio>
#include <iostream>
#include <fstream>
#include <vector>
#include <unordered_map>
#include <unordered_set>
#include <functional>

#include <BankTypes.h>

#include <gsl-lite.hpp>

#include <sys/types.h>

#include "odin.hpp"
#include "raw_bank.hpp"
#include "mdf_header.hpp"

namespace Allen {
  const std::unordered_map<LHCb::RawBank::BankType, BankTypes> bank_types = {{LHCb::RawBank::VP, BankTypes::VP},
                                                                             {LHCb::RawBank::UT, BankTypes::UT},
                                                                             {LHCb::RawBank::FTCluster, BankTypes::FT},
                                                                             {LHCb::RawBank::Muon, BankTypes::MUON}};

  using buffer_map = std::unordered_map<BankTypes, std::pair<std::vector<char>, std::vector<unsigned int>>>;

  struct IO {
    bool good = false;
    std::function<ssize_t(char*, size_t)> read;
    std::function<ssize_t(char const*, size_t)> write;
    std::function<void(void)> close;
  };
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

  LHCb::ODIN decode_odin(const LHCb::RawBank* bank);

} // namespace MDF
