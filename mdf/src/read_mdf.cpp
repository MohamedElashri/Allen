/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <cstdio>
#include <cstring>
#include <unistd.h>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <vector>
#include <array>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "mdf_header.hpp"
#include "read_mdf.hpp"
#include "Event/RawBank.h"
#include "raw_helpers.hpp"

#include <Common.h>

#ifdef WITH_ROOT
#include "root_mdf.hpp"
#endif

namespace {
  using gsl::span;
  using std::array;
  using std::cerr;
  using std::cout;
  using std::ifstream;
  using std::make_tuple;
  using std::vector;
} // namespace

Allen::IO MDF::open(std::string const& filepath, int flags, int mode)
{
  if (::strncmp(filepath.c_str(), "root:", 5) == 0) {
#ifdef WITH_ROOT
    return ROOT::open(filepath, flags);
#else
    cout << "Allen was not compiled with ROOT support\n";
    return {};
#endif
  }
  else {
    int fd = ::open(filepath.c_str(), flags, mode);
    return {true,
            [fd](char* ptr, size_t size) { return ::read(fd, ptr, size); },
            [fd](char const* ptr, size_t size) { return ::write(fd, ptr, size); },
            [fd] { return ::close(fd); }};
  }
}

// return eof, error, span that covers all banks in the event
std::tuple<bool, bool, gsl::span<char>> MDF::read_event(
  Allen::IO& input,
  LHCb::MDFHeader& h,
  gsl::span<char> buffer,
  std::vector<char>& decompression_buffer,
  bool checkChecksum,
  bool dbg)
{
  int rawSize = sizeof(LHCb::MDFHeader);

  // Read the first part directly into the header
  ssize_t n_bytes = input.read(reinterpret_cast<char*>(&h), rawSize);
  if (n_bytes > 0) {
    return read_banks(input, h, buffer, decompression_buffer, checkChecksum, dbg);
  }
  else if (n_bytes == 0) {
    cout << "Cannot read more data (Header). End-of-File reached.\n";
    return {true, false, {}};
  }
  else {
    cerr << "Failed to read header " << strerror(errno) << "\n";
    return {false, true, {}};
  }
}

// return eof, error, span that covers all banks in the event
std::tuple<bool, bool, gsl::span<char>> MDF::read_banks(
  Allen::IO& input,
  const LHCb::MDFHeader& h,
  gsl::span<char> buffer,
  std::vector<char>& decompression_buffer,
  bool checkChecksum,
  bool dbg)
{
  size_t rawSize = LHCb::MDFHeader::sizeOf(h.headerVersion());
  unsigned int checksum = h.checkSum();
  int compress = h.compression() & 0xF;
  int expand = (h.compression() >> 4) + 1;
  int hdrSize = h.subheaderLength();
  size_t readSize = h.recordSize() - rawSize;
  int chkSize = h.recordSize() - 4 * sizeof(int);
  int alloc_len = (2 * rawSize + readSize + sizeof(LHCb::RawBank) + sizeof(int) + (compress ? expand * readSize : 0));

  // Build the DAQ status bank that contains the header
  auto build_bank = [rawSize, &h](char* address) {
    auto* b = reinterpret_cast<LHCb::RawBank*>(address);
    b->setMagic();
    b->setType(LHCb::RawBank::DAQ);
    b->setSize(rawSize);
    b->setVersion(DAQ_STATUS_BANK);
    b->setSourceID(0);
    ::memcpy(b->data(), &h, sizeof(LHCb::MDFHeader));
    return b;
  };

  if (dbg) {
    cout << "Size: " << std::setw(6) << h.recordSize() << " Compression: " << compress << " Checksum: 0x" << std::hex
         << checksum << std::dec << "\n";
  }

  // accomodate for potential padding of MDF header bank!
  if (static_cast<size_t>(buffer.size()) < alloc_len + sizeof(int) + sizeof(LHCb::RawBank)) {
    cerr << "Failed to read banks: buffer too small " << buffer.size() << " "
         << alloc_len + sizeof(int) + sizeof(LHCb::RawBank) << "\n";
    return {false, true, {}};
  }

  // build the DAQ status bank that contains the header and subheader as payload
  auto* b = build_bank(buffer.data());
  int bnkSize = b->totalSize();
  char* bptr = (char*) b->data();

  // Read the subheader and put it directly after the MDFHeader
  input.read(bptr + sizeof(LHCb::MDFHeader), hdrSize);

  // The header and subheader are complete in the buffer,
  auto* hdr = reinterpret_cast<LHCb::MDFHeader*>(bptr);

  // If requrested compare the checksum in the header versus the data
  auto test_checksum = [&hdr, checksum, checkChecksum](char* const buffer, int size) {
    // Checksum if requested
    if (!checkChecksum) {
      hdr->setChecksum(0);
    }
    else if (checksum != 0) {
      auto c = LHCb::hash32Checksum(buffer + 4 * sizeof(int), size);
      if (checksum != c) {
        cerr << "Checksum doesn't match: " << std::hex << c << " instead of 0x" << checksum << std::dec << "\n";
        return false;
      }
    }
    return true;
  };

  // Decompress or read uncompressed data directly
  if (compress != 0) {
    decompression_buffer.reserve(readSize + rawSize);

    // Need to copy header and subheader to get checksum right
    ::memcpy(decompression_buffer.data(), hdr, rawSize);

    // Read compressed data
    ssize_t n_bytes = input.read(decompression_buffer.data() + rawSize, readSize);
    if (n_bytes == 0) {
      cout << "Cannot read more data (Header). End-of-File reached.\n";
      return {true, false, {}};
    }
    else if (n_bytes == -1) {
      cerr << "Failed to read banks " << strerror(errno) << "\n";
      return {false, true, {}};
    }

    // calculate and compare checksum
    if (!test_checksum(decompression_buffer.data(), chkSize)) {
      return {false, true, {}};
    }

    // compressed data starts after the MDFHeader and SubHeader
    auto* src = reinterpret_cast<unsigned char*>(decompression_buffer.data()) + rawSize;
    auto* ptr = reinterpret_cast<unsigned char*>(buffer.data()) + bnkSize;
    size_t space_size = buffer.size() - bnkSize;
    size_t new_len = 0;

    // decompress payload
    if (LHCb::decompressBuffer(compress, ptr, space_size, src, hdr->size(), new_len)) {
      hdr->setSize(new_len);
      hdr->setCompression(0);
      hdr->setChecksum(0);
      return {false, false, {buffer.data(), static_cast<span_size_t<char>>(bnkSize + new_len)}};
    }
    else {
      cerr << "Failed to decompress data\n";
      return {false, true, {}};
    }
  }
  else {
    // Read uncompressed data from file
    ssize_t n_bytes = input.read(bptr + rawSize, readSize);
    if (n_bytes == 0) {
      cout << "Cannot read more data (Header). End-of-File reached.\n";
      return {true, false, {}};
    }
    else if (n_bytes == -1) {
      cerr << "Failed to read banks " << strerror(errno) << "\n";
      return {false, true, {}};
    }

    // calculate and compare checksum
    if (!test_checksum(bptr, chkSize)) {
      return {false, true, {}};
    }
    return {
      false, false, {buffer.data(), static_cast<span_size_t<char>>(bnkSize + static_cast<unsigned int>(readSize))}};
  }
}

// Decode the ODIN bank
LHCb::ODIN MDF::decode_odin(gsl::span<unsigned const> data, unsigned const version)
{
  // we just assume the buffer has the right size and cross fingers.
  // note that we only support the default bank version in Allen
  if (version == 6) {
    return LHCb::ODIN::from_version<6>(data);
  }
  else {
    return LHCb::ODIN(data);
  }
}

void MDF::dump_hex(const char* start, int size)
{
  const auto* content = start;
  size_t m = 0;
  cout << std::hex << std::setw(7) << m << " ";
  auto prev = cout.fill();
  auto flags = cout.flags();
  while (content < start + size) {
    if (m % 32 == 0 && m != 0) {
      cout << "\n" << std::setw(7) << m << " ";
    }
    cout << std::setw(2) << std::setfill('0') << ((int) (*content) & 0xff);
    ++m;
    if (m % 2 == 0) {
      cout << " ";
    }
    ++content;
  }
  cout << std::dec << std::setfill(prev) << "\n";
  cout.setf(flags);
}
