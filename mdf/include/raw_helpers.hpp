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
#ifndef RAW_HELPERS_H
#define RAW_HELPERS_H 1

#include <iostream>

namespace LHCb {

  // Forward declarations
  unsigned int hash32Checksum(const void* ptr, size_t len);
  unsigned int adler32Checksum(unsigned int old, const char* buf, size_t len);

  /// Generate XOR Checksum
  unsigned int genChecksum(int flag, const void* ptr, size_t len);

  bool decompressBuffer(
    int algtype,
    unsigned char* tar,
    size_t tar_len,
    unsigned char* src,
    size_t src_len,
    size_t& new_len);

} // namespace LHCb

#endif
