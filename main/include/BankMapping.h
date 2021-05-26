/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <unordered_map>

#include "BankTypes.h"
#include "Event/RawBank.h"

namespace Allen {
  const std::unordered_map<LHCb::RawBank::BankType, BankTypes> bank_types = {
    {LHCb::RawBank::VP, BankTypes::VP},
    {LHCb::RawBank::UT, BankTypes::UT},
    {LHCb::RawBank::FTCluster, BankTypes::FT},
    {LHCb::RawBank::Muon, BankTypes::MUON},
    {LHCb::RawBank::ODIN, BankTypes::ODIN},
    {LHCb::RawBank::HcalPacked, BankTypes::HCal},
    {LHCb::RawBank::EcalPacked, BankTypes::ECal},
    {LHCb::RawBank::OTError, BankTypes::OTError}, // used for PV MC info
    {LHCb::RawBank::OTRaw, BankTypes::OTRaw},     // used for track MC info
}
