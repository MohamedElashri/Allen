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
#include <cstring>

#include "Event/RawBank.h"
#include "write_mdf.hpp"

size_t Allen::add_raw_bank(
  unsigned char const type,
  unsigned char const version,
  short const sourceID,
  gsl::span<char const> fragment,
  char* buffer)
{
  auto* bank = reinterpret_cast<LHCb::RawBank*>(buffer);
  bank->setMagic();
  bank->setSize(fragment.size());
  bank->setType(static_cast<LHCb::RawBank::BankType>(type));
  bank->setVersion(version);
  bank->setSourceID(sourceID);
  std::memcpy(bank->begin<char>(), fragment.data(), fragment.size());

  // pad to a multiple of 4 bytes
  auto const padded_size = padded_bank_size(fragment.size());
  std::memset(bank->begin<char>() + fragment.size(), 0, padded_size - fragment.size());
  if (static_cast<LHCb::RawBank::BankType>(type) < LHCb::RawBank::BankType::DaqErrorFragmentThrottled)
    assert(static_cast<unsigned long>(bank->totalSize()) == bank->hdrSize() + padded_size);

  return bank->totalSize();
}
