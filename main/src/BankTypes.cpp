/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <map>
#include <string>
#include <optional>
#include <BankTypes.h>
#include <Common.h>

namespace {
  const std::map<BankTypes, std::string> BankNames = {{BankTypes::VP, "VP"},
                                                      {BankTypes::VP, "VPRetinaCluster"},
                                                      {BankTypes::UT, "UT"},
                                                      {BankTypes::FT, "FTCluster"},
                                                      {BankTypes::MUON, "Muon"},
                                                      {BankTypes::ODIN, "ODIN"},
                                                      {BankTypes::Rich1, "Rich1"},
                                                      {BankTypes::Rich2, "Rich2"},
                                                      {BankTypes::HCal, "HCal"},
                                                      {BankTypes::ECal, "ECal"},
                                                      {BankTypes::MCTracks, "tracks"},
                                                      {BankTypes::MCVertices, "PVs"}};
}

std::string bank_name(BankTypes type)
{
  auto it = BankNames.find(type);
  if (it != end(BankNames)) {
    return it->second;
  }
  else {
    return "Unknown";
  }
}

BankTypes bank_type(std::string bank_name)
{
  auto it = std::find_if(
    BankNames.begin(), BankNames.end(), [bank_name](const auto& entry) { return entry.second == bank_name; });
  if (it != end(BankNames)) {
    return it->first;
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
