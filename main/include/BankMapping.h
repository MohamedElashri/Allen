/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <unordered_map>
#include <Event/RawBank.h>

#include "sourceid.h"
#include "BankTypes.h"

namespace Allen {
  const std::unordered_map<LHCb::RawBank::BankType, BankTypes> bank_types = {
    {LHCb::RawBank::VP, BankTypes::VP},
    {LHCb::RawBank::VPRetinaCluster, BankTypes::VPRetinaCluster},
    {LHCb::RawBank::UT, BankTypes::UT},
    {LHCb::RawBank::FTCluster, BankTypes::FT},
    {LHCb::RawBank::Muon, BankTypes::MUON},
    {LHCb::RawBank::ODIN, BankTypes::ODIN},
    {LHCb::RawBank::HcalPacked, BankTypes::HCal},
    {LHCb::RawBank::EcalPacked, BankTypes::ECal},
    {LHCb::RawBank::OTError, BankTypes::OTError}, // used for PV MC info
    {LHCb::RawBank::OTRaw, BankTypes::OTRaw}};    // used for track MC info

  const std::unordered_map<SourceIdSys, BankTypes> subdetectors = {
    {SourceIdSys::SourceIdSys_ODIN, BankTypes::ODIN},
    {SourceIdSys::SourceIdSys_VELO_A, BankTypes::VP},
    {SourceIdSys::SourceIdSys_VELO_C, BankTypes::VP},
    {SourceIdSys::SourceIdSys_VELO_A, BankTypes::VPRetinaCluster},
    {SourceIdSys::SourceIdSys_VELO_C, BankTypes::VPRetinaCluster},
    {SourceIdSys::SourceIdSys_UT_A, BankTypes::UT},
    {SourceIdSys::SourceIdSys_UT_C, BankTypes::UT},
    {SourceIdSys::SourceIdSys_SCIFI_A, BankTypes::FT},
    {SourceIdSys::SourceIdSys_SCIFI_C, BankTypes::FT},
    {SourceIdSys::SourceIdSys_MUON_A, BankTypes::MUON},
    {SourceIdSys::SourceIdSys_MUON_C, BankTypes::MUON},
    {SourceIdSys::SourceIdSys_HCAL, BankTypes::HCal},
    {SourceIdSys::SourceIdSys_ECAL, BankTypes::ECal}};

  const unsigned NSourceIdSys = to_integral(SourceIdSys::SourceIdSys_TDET) + 1;
} // namespace Allen
