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
#include "root_mdf.hpp"

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
    return ROOT::open(filepath, flags);
  }
  else {
    int fd = ::open(filepath.c_str(), flags, mode);
    if (fd < 0) {
      cerr << "Failed to open file " << filepath << ": " << strerror(errno) << "\n";
      return {};
    }
    else {
      return {true,
              [fd](char* ptr, size_t size) { return ::read(fd, ptr, size); },
              [fd](char const* ptr, size_t size) { return ::write(fd, ptr, size); },
              [fd] { return ::close(fd); }};
    }
  }
}

// return eof, error, span that covers all banks in the event
std::tuple<bool, bool, std::vector<std::tuple<int, gsl::span<const char>>>> MDF::read_event(
  Allen::IO& input,
  LHCb::MDFHeader& h,
  gsl::span<char> buffer,
  std::vector<char>& decompression_buffer,
  bool checkChecksum,
  bool dbg)
{
  int raw_size = sizeof(LHCb::MDFHeader);
  std::vector<std::tuple<int, span<const char>>> events;

  // Read the first part directly into the header
  ssize_t n_bytes = input.read(reinterpret_cast<char*>(&h), raw_size);
  if (n_bytes > 0) {
    auto [eof, error, bank_span] = read_banks(input, h, buffer, decompression_buffer, checkChecksum, dbg);
    char const* payload = bank_span.data();
    auto const* first_bank = reinterpret_cast<LHCb::RawBank const*>(payload);
    if (first_bank->magic() != LHCb::RawBank::MagicPattern) {
      cout << "Bad magic in first bank.\n";
      return {false, true, {}};
    }
    else if (first_bank->type() == LHCb::RawBank::DAQ && first_bank->version() == DAQ_STATUS_BANK) {
      // skip the DAQ status bank
      payload += first_bank->totalSize();
      first_bank = reinterpret_cast<LHCb::RawBank const*>(payload);
    }
    if (first_bank->type() != LHCb::RawBank::TAEHeader) {
      events.emplace_back(0, bank_span);
      return {eof, error, events};
    }
    else {
      size_t n_blocks = first_bank->size() / sizeof(int) / 3;
      events.reserve(n_blocks);
      int const* block = reinterpret_cast<int const*>(first_bank);
      block += 2;                         // skip bank header
      payload += first_bank->totalSize(); // skip TAE bank body
      for (size_t i = 0; i < n_blocks; ++i) {
        int bx = *block++;
        int offset = *block++;
        int size = *block++;
        events.emplace_back(
          bx, gsl::span<const char> {payload + offset, static_cast<gsl::span<const char>::size_type>(size)});
      }
      assert(events.size() == n_blocks);
      return {eof, error, events};
    }
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
std::tuple<bool, bool, gsl::span<const char>> MDF::read_banks(
  Allen::IO& input,
  const LHCb::MDFHeader& h,
  gsl::span<char> buffer,
  std::vector<char>& decompression_buffer,
  bool checkChecksum,
  bool dbg)
{
  size_t raw_size = LHCb::MDFHeader::sizeOf(h.headerVersion());
  unsigned int checksum = h.checkSum();
  int compress = h.compression() & 0xF;
  int expand = (h.compression() >> 4) + 1;
  int hdrSize = h.subheaderLength();
  size_t readSize = h.recordSize() - raw_size;
  int chkSize = h.recordSize() - 4 * sizeof(int);
  int alloc_len = (2 * raw_size + readSize + sizeof(LHCb::RawBank) + sizeof(int) + (compress ? expand * readSize : 0));

  // Build the DAQ status bank that contains the header
  auto build_bank = [raw_size, &h](char* address) {
    auto* b = reinterpret_cast<LHCb::RawBank*>(address);
    b->setMagic();
    b->setType(LHCb::RawBank::DAQ);
    b->setSize(raw_size);
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
    decompression_buffer.reserve(readSize + raw_size);

    // Need to copy header and subheader to get checksum right
    ::memcpy(decompression_buffer.data(), hdr, raw_size);

    // Read compressed data
    ssize_t n_bytes = input.read(decompression_buffer.data() + raw_size, readSize);
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
    auto* src = reinterpret_cast<unsigned char*>(decompression_buffer.data()) + raw_size;
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
    ssize_t n_bytes = input.read(bptr + raw_size, readSize);
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

void MDF::dump_hex(const char* start, int size, std::ostream& out)
{
  const auto* content = start;
  size_t m = 0;
  out << std::hex << std::setw(7) << m << " ";
  auto prev = out.fill();
  auto flags = out.flags();
  while (content < start + size) {
    if (m % 32 == 0 && m != 0) {
      out << "\n" << std::setw(7) << m << " ";
    }
    out << std::setw(2) << std::setfill('0') << ((int) (*content) & 0xff);
    ++m;
    if (m % 2 == 0) {
      out << " ";
    }
    ++content;
  }
  out << std::dec << std::setfill(prev) << "\n";
  out.setf(flags);
}
