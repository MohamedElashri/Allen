/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#ifndef BANKTYPES_H
#define BANKTYPES_H 1

#include <type_traits>
#include <iostream>
#include <unordered_map>
#include <unordered_set>
#include <vector>
#include <cassert>
#include <gsl/span>
#include "nlohmann/json.hpp"
#include "Common.h"

constexpr auto NBankTypes = 11;
enum class BankTypes { VP, UT, FT, MUON, ODIN, MCTracks, MCVertices, Rich1, Rich2, ECal, HCal, Unknown };

// Average size of all raw banks of a given type per
// subdetector, in kB, measured in simulated minbias events.
// FIXME: make this configurable
const std::unordered_map<BankTypes, float> BankSizes = {{BankTypes::VP, 20.f},
                                                        {BankTypes::UT, 12.f},
                                                        {BankTypes::FT, 15.f},
                                                        {BankTypes::MUON, 4.f},
                                                        {BankTypes::Rich1, 35.f},
                                                        {BankTypes::Rich2, 35.f},
                                                        {BankTypes::HCal, 5.1f},
                                                        {BankTypes::ECal, 15.f},
                                                        {BankTypes::ODIN, 1.f},
                                                        {BankTypes::MCTracks, 110.f},
                                                        {BankTypes::MCVertices, 0.3f}};

// Average measured event size, measured
// FIXME: make this configurable
constexpr float average_event_size = 65.f;
// Safety margin
// FIXME: make this configurable
constexpr float bank_size_fudge_factor = 1.5f;

/**
 * @brief      Get the name of the type of a given BankType
 * @param      BankType
 * @return     bank type name
 */
std::string bank_name(BankTypes type);

/**
 * @brief      Get the type of a bank from its name
 * @param      BankType
 * @return     bank type name
 */
BankTypes bank_type(std::string bank_name);

template<typename ENUM>
constexpr auto to_integral(ENUM e) -> typename std::underlying_type<ENUM>::type
{
  return static_cast<typename std::underlying_type<ENUM>::type>(e);
}

struct BanksAndOffsets {
  std::vector<gsl::span<const char>> fragments;
  gsl::span<unsigned const> offsets;
  size_t fragments_mem_size = 0;
  gsl::span<unsigned const> sizes;
  gsl::span<unsigned const> types;
  int version = 0;
};

template<BankTypes... BANKS>
std::unordered_set<BankTypes> banks_set()
{
  return std::unordered_set<BankTypes> {BANKS...};
}

// Conversion functions from and to json
void from_json(const nlohmann::json& j, BankTypes& b);

void to_json(nlohmann::json& j, const BankTypes& b);

#endif
