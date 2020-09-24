/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <cstring>

#include "Event/RawBank.h"
#include "write_mdf.hpp"

size_t add_raw_bank(
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
  return bank->size() + bank->hdrSize();
}
