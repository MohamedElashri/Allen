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
                                                      {BankTypes::UT, "UT"},
                                                      {BankTypes::FT, "FTCluster"},
                                                      {BankTypes::MUON, "Muon"},
                                                      {BankTypes::ODIN, "ODIN"},
                                                      {BankTypes::Rich, "Rich"},
                                                      {BankTypes::HCal, "HCal"},
                                                      {BankTypes::ECal, "ECal"},
                                                      {BankTypes::OTRaw, "OTRaw"},
                                                      {BankTypes::OTError, "OTError"}};
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
