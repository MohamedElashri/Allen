#ifndef BANKTYPES_H
#define BANKTYPES_H 1

#include <type_traits>
#include <iostream>
#include <unordered_map>
#include <unordered_set>
#include <gsl-lite.hpp>

namespace {
  using gsl::span;
}

constexpr auto NBankTypes = 4;
enum class BankTypes { VP, UT, FT, MUON };

// Average size of all raw banks of a given type per
// subdetector, in kB, measured in simulated minbias events.
// FIXME: make this configurable
const std::unordered_map<BankTypes, float> BankSizes = {{BankTypes::VP, 51.77f},
                                                        {BankTypes::UT, 31.38f},
                                                        {BankTypes::FT, 54.47f},
                                                        {BankTypes::MUON, 5.13f}};
// Average measured event size, measured
// FIXME: make this configurable
constexpr float average_event_size = 65.f;
// Safety margin
// FIXME: make this configurable
constexpr float bank_size_fudge_factor = 1.2f;

/**
 * @brief      Get the name of the type of a given BankType
 * @param      BankType
 * @return     bank type name
 */
std::string bank_name(BankTypes type);

template<typename ENUM>
constexpr auto to_integral(ENUM e) -> typename std::underlying_type<ENUM>::type
{
  return static_cast<typename std::underlying_type<ENUM>::type>(e);
}

using BanksAndOffsets = std::tuple<std::vector<span<const char>>, size_t, span<const unsigned int>>;

template<BankTypes... BANKS>
std::unordered_set<BankTypes> banks_set()
{
  return std::unordered_set<BankTypes> {BANKS...};
}

#endif
