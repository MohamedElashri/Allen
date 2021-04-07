/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "BackendCommon.h"

struct CaloRawBank {
  uint32_t source_id;
  uint32_t const* data;
  uint32_t const* end;

  // For Allen format
  __device__ CaloRawBank(const char* raw_bank, uint32_t s) :
    CaloRawBank {*(uint32_t*) raw_bank, raw_bank + sizeof(uint32_t), raw_bank + s}
  {}

  // For MEP format
  __device__ CaloRawBank(const uint32_t sid, const char* fragment, const char* e) :
    source_id {sid}, data {reinterpret_cast<uint32_t const*>(fragment)}, end {reinterpret_cast<uint32_t const*>(e)}
  {}
};
