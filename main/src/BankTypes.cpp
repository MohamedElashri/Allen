/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
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
                                                      {"PVs", BankTypes::MCVertices},
                                                      {"Gen", BankTypes::Gen}};
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
