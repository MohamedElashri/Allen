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

constexpr auto NBankTypes = 8;
enum class BankTypes { VP, UT, FT, MUON, Rich, ECal, HCal, ODIN };

// Average size of all raw banks of a given type per
// subdetector, in kB, measured in simulated minbias events.
// FIXME: make this configurable
const std::unordered_map<BankTypes, float> BankSizes = {{BankTypes::VP, 12.f},
                                                        {BankTypes::UT, 7.f},
                                                        {BankTypes::FT, 9.f},
                                                        {BankTypes::MUON, 1.2f},
                                                        {BankTypes::Rich, 21.f},
                                                        {BankTypes::HCal, 2.1},
                                                        {BankTypes::ECal, 8.f}};

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

using BanksAndOffsets = std::tuple<span<const char>, span<const unsigned int>>;

template<BankTypes... BANKS>
std::unordered_set<BankTypes> banks_set()
{
  return std::unordered_set<BankTypes> {BANKS...};
}

#endif
