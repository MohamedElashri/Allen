/*****************************************************************************\
* (c) Copyright 2000-2021 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <iostream>
#include <string>
#include <unordered_set>

#include <Event/RawBank.h>

// Parsers are in namespace LHCb for ADL to work.
namespace LHCb {

  StatusCode parse(RawBank::BankType& result, const std::string& in);

  StatusCode parse(std::unordered_set<RawBank::BankType>& s, const std::string& in);

  std::ostream& toStream(const RawBank::BankType& bt, std::ostream& s);
} // namespace LHCb
