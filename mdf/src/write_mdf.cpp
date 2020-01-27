#include <cstring>

#include "raw_bank.hpp"
#include "write_mdf.hpp"

size_t add_raw_bank(
  unsigned char const type,
  unsigned char const version,
  short const sourceID,
  gsl::span<char const> fragment,
  char* buffer)
{
  static_assert(LHCb::RawBank::hdrSize() == 4 * sizeof(short));

  auto const bank_size = LHCb::RawBank::hdrSize() + fragment.size();
  short* short_buf = reinterpret_cast<short*>(buffer);
  *short_buf = static_cast<unsigned short>(LHCb::RawBank::MagicPattern);
  *(short_buf + 1) = bank_size;
  char* char_buf = buffer + 2 * sizeof(short);
  *char_buf = type;
  *(char_buf + 1) = version;
  *(short_buf + 3) = sourceID;
  std::memcpy(buffer + LHCb::RawBank::hdrSize(), fragment.data(), fragment.size());
  return bank_size;
}
