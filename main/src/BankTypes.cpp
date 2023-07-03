/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <map>
#include <string>
#include <optional>
#include <BankTypes.h>
#include <Common.h>
#include <iostream>

namespace {
  const std::map<std::string, BankTypes> BankNames = {{"VP", BankTypes::VP},
                                                      {"UT", BankTypes::UT},
                                                      {"FTCluster", BankTypes::FT},
                                                      {"Muon", BankTypes::MUON},
                                                      {"ODIN", BankTypes::ODIN},
                                                      {"Rich1", BankTypes::Rich1},
                                                      {"Rich2", BankTypes::Rich2},
                                                      {"HCal", BankTypes::HCal},
                                                      {"ECal", BankTypes::ECal},
                                                      {"Plume", BankTypes::Plume},
                                                      {"tracks", BankTypes::MCTracks},
                                                      {"PVs", BankTypes::MCVertices}};
}

std::string bank_name(BankTypes bank_type)
{
  auto it = std::find_if(
    BankNames.begin(), BankNames.end(), [bank_type](const auto& entry) { return entry.second == bank_type; });
  if (it != end(BankNames)) {
    return it->first;
  }
  else {
    return "Unknown";
  }
}

BankTypes bank_type(std::string bank_name)
{
  auto it = BankNames.find(bank_name);
  if (it != end(BankNames)) {
    return it->second;
  }
  else {
    return BankTypes::Unknown;
  }
}

void from_json(const nlohmann::json& j, BankTypes& b)
{
  std::string s = j.get<std::string>();
  b = bank_type(s);
  if (b == BankTypes::Unknown) {
    throw StrException {"Failed to parse BankType " + s + "."};
  }
}

void to_json(nlohmann::json& j, const BankTypes& b) { j = bank_name(b); }
