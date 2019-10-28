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
#include <Logger.h>
#include "mdf_header.hpp"
#include "read_mdf.hpp"
#include "raw_bank.hpp"
#include "raw_helpers.hpp"

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

Allen::IO MDF::open(std::string const& filepath, int flags)
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
    int fd = ::open(filepath.c_str(), flags);
    return {true,
            [fd](char* ptr, size_t size) { return ::read(fd, ptr, size); },
            [fd](char const* ptr, size_t size) { return ::write(fd, ptr, size); },
            [fd] { return ::close(fd); }};
  }
}

std::tuple<size_t, Allen::buffer_map, std::vector<LHCb::ODIN>> MDF::read_events(
  size_t n,
  const std::vector<std::string>& files,
  const std::unordered_set<BankTypes>& types,
  bool checkChecksum,
  size_t start_event)
{

  Allen::buffer_map buffers;
  for (auto bank_type : types) {
    auto r = buffers.emplace(bank_type, make_pair(vector<char> {}, vector<unsigned int> {}));
    // Reserve some memory
    auto& banks = r.first->second.first;
    banks.reserve(n * 100 * 1024);
    // Reserve for 100 banks per event, more than enough
    auto& offsets = r.first->second.second;
    offsets.reserve(n * 100);
    offsets.push_back(0);
  }

  vector<LHCb::ODIN> odins;
  odins.reserve(n);

  // Some storage for reading the events into
  LHCb::MDFHeader header;
  vector<char> buffer(1024 * 1024);

  bool eof = false, error = false;

  gsl::span<const char> bank_span;
  size_t n_read = 0;

  array<std::vector<uint32_t>, NBankTypes> bank_offsets;
  array<std::vector<uint32_t>, NBankTypes> bank_datas;
  vector<char> decompression_buffer(1024 * 1024);

  // Lambda to copy data from the event-local buffer to the global
  // one, while keeping the global buffer's size consistent with its
  // content
  auto copy_data = [](unsigned int& event_offset, vector<char>& buf, const void* source, size_t s) {
    size_t n_chars = buf.size();
    for (size_t i = 0; i < s; ++i) {
      buf.emplace_back(0);
    }
    ::memcpy(&buf[n_chars], source, s);
    event_offset += s;
  };

  for (const auto& filename : files) {
    auto input = MDF::open(filename.c_str(), O_RDONLY);
    if (!input.good) {
      cout << "failed to open file " << filename << " " << strerror(errno) << "\n";
      break;
    }

    while (n_read++ < n) {

      std::tie(eof, error, bank_span) = read_event(input, header, buffer, decompression_buffer, checkChecksum);
      if (eof || error) {
        break;
      }

      // Skip some events
      if (n_read < start_event) {
        continue;
      }

      // Clear bank offsets
      for (auto& bo : bank_offsets) {
        bo.clear();
        bo.push_back(0);
      }

      // Clear bank data
      for (auto& bd : bank_datas) {
        bd.clear();
      }

      // Put the banks in the event-local buffers
      const auto* bank = bank_span.begin();
      const auto* end = bank_span.end();
      while (bank < end) {
        const auto* b = reinterpret_cast<const LHCb::RawBank*>(bank);
        if (b->magic() != LHCb::RawBank::MagicPattern) {
          cout << "magic pattern failed: " << std::hex << b->magic() << std::dec << "\n";
        }

        // Decode the odin bank
        if (b->type() == LHCb::RawBank::ODIN) {
          odins.emplace_back(decode_odin(b->version(), b->data()));
        }

        // Check if Allen processes this type of bank
        auto bank_type_it = Allen::bank_types.find(b->type());
        if (bank_type_it == Allen::bank_types.end()) {
          bank += b->totalSize();
          continue;
        }

        // Check if we want this bank
        auto buf_it = buffers.find(bank_type_it->second);
        if (buf_it == buffers.end()) {
          bank += b->totalSize();
          continue;
        }

        auto index = to_integral(bank_type_it->second);
        auto& bank_data = bank_datas[index];
        auto& offsets = bank_offsets[index];
        auto offset = offsets.back() / sizeof(uint32_t);

        // Store this bank in the event-local buffers
        bank_data.push_back(b->sourceID());
        offset++;

        auto b_start = b->begin<uint32_t>();
        auto b_end = b->end<uint32_t>();

        while (b_start != b_end) {
          const uint32_t raw_data = *b_start;
          bank_data.emplace_back(raw_data);

          b_start++;
          offset++;
        }

        // Record raw bank offset
        offsets.push_back(offset * sizeof(uint32_t));

        // Move to next raw bank
        bank += b->totalSize();
      }

      // Fill the output buffers from the event-local buffers in the right format:
      // - number of raw banks (uint32_t)
      // - raw bank offset within event as number of char (one more than number of banks)
      // - raw bank data as uint32_t
      for (auto& entry : buffers) {
        auto& buf = entry.second.first;

        auto index = to_integral(entry.first);
        auto& event_offsets = entry.second.second;
        auto event_offset = event_offsets.back();

        // Copy in number of banks
        const auto& offsets = bank_offsets[index];
        uint32_t n_banks = offsets.size() - 1;
        copy_data(event_offset, buf, &n_banks, sizeof(n_banks));

        // Copy in bank offsets
        copy_data(event_offset, buf, offsets.data(), offsets.size() * sizeof(uint32_t));

        // Copy in bank data
        const auto& bank_data = bank_datas[index];
        copy_data(event_offset, buf, bank_data.data(), bank_data.size() * sizeof(uint32_t));

        event_offsets.push_back(event_offset);
      }
    }
    input.close();
  }
  n_read = n_read > 0 ? n_read - 1 : 0;
  return make_tuple(n_read, std::move(buffers), std::move(odins));
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
  if (buffer.size() < alloc_len + sizeof(int) + sizeof(LHCb::RawBank)) {
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
    else {
      auto c = LHCb::genChecksum(1, buffer + 4 * sizeof(int), size);
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
      cout << "Cannot read more data  (Header). End-of-File reached.\n";
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
      return {false, false, {buffer.data(), bnkSize + new_len}};
    }
    else {
      cerr << "Failed to read compressed data\n";
      return {false, true, {}};
    }
  }
  else {
    // Read uncompressed data from file
    ssize_t n_bytes = input.read(bptr + rawSize, readSize);
    if (n_bytes == 0) {
      cout << "Cannot read more data  (Header). End-of-File reached.\n";
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
    return {false, false, {buffer.data(), bnkSize + static_cast<unsigned int>(readSize)}};
  }
}

// Decode the ODIN bank
LHCb::ODIN MDF::decode_odin(unsigned int version, unsigned int const* odinData)
{
  LHCb::ODIN odin;
  unsigned long long temp64 {0};
  unsigned int temp32 {0};

  // Fill the ODIN object
  odin.version = version;
  odin.run_number = odinData[LHCb::ODIN::Data::RunNumber];
  odin.orbit_number = odinData[LHCb::ODIN::Data::OrbitNumber];

  temp64 = odinData[LHCb::ODIN::Data::L0EventIDHi];
  odin.event_number = (temp64 << 32) + odinData[LHCb::ODIN::Data::L0EventIDLo];

  temp32 = odinData[LHCb::ODIN::Data::EventType];
  odin.event_type =
    (temp32 & LHCb::ODIN::EventTypeMasks::EventTypeMask) >> LHCb::ODIN::EventTypeBitsEnum::EventTypeBits;
  odin.calibration_step =
    (temp32 & LHCb::ODIN::EventTypeMasks::CalibrationStepMask) >> LHCb::ODIN::EventTypeBitsEnum::CalibrationStepBits;

  odin.tck = odinData[LHCb::ODIN::Data::TriggerConfigurationKey];
  return odin;
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
