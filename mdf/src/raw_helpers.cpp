/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <cstring>
#include "raw_helpers.hpp"

#ifdef WITH_ROOT
#include <RZip.h>
#endif

/// one-at-time hash function
// Public domain code from https://burtleburtle.net/bob/hash/doobs.html
unsigned int LHCb::hash32Checksum(const void* ptr, size_t len)
{
  unsigned int hash = 0;
  const char* k = (const char*) ptr;
  for (size_t i = 0; i < len; ++i, ++k) {
    hash += *k;
    hash += (hash << 10);
    hash ^= (hash >> 6);
  }
  hash += (hash << 3);
  hash ^= (hash >> 11);
  hash += (hash << 15);
  return hash;
}

/// Decompress opaque data buffer
bool LHCb::decompressBuffer(
  int algtype,
  unsigned char* tar,
  size_t tar_len,
  unsigned char* src,
  size_t src_len,
  size_t& new_len)
{
#ifdef WITH_ROOT
  int in_len = 0, out_len = 0, res_len = 0;
#endif
  switch (algtype) {
  case 0:
    if (tar != src && tar_len >= src_len) {
      new_len = src_len;
      ::memcpy(tar, src, src_len);
      return true;
    }
    break;
  case 1:
  case 2:
  case 3:
  case 4:
  case 5:
  case 6:
  case 7:
  case 8:
  case 9:
#ifdef WITH_ROOT
    in_len = static_cast<int>(src_len);
    out_len = static_cast<int>(tar_len);
    res_len = 0;
    ::R__unzip(&in_len, src, &out_len, tar, &res_len);
    if (res_len > 0) {
      new_len = static_cast<size_t>(res_len);
      return true;
    }
#endif
    break;
  default: break;
  }
  return false;
}
