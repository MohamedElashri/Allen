#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <iostream>
#include <vector>
#include <cstring>
#include <cassert>

#include <gsl/gsl>
#include <eb_header.hpp>
#include <mdf_header.hpp>
#include <read_mep.hpp>
#include <BankTypes.h>

namespace {
  using std::cerr;
  using std::cout;
} // namespace

/**
 * @brief      Read a mep from a file
 *
 * @param      file descriptor to read from
 * @param      buffer to store data in
 *
 * @return     (eof, success, mep_header, span of mep data)
 */
std::tuple<bool, bool, EB::Header, gsl::span<char const>> MEP::read_mep(Allen::IO& input, std::vector<char>& buffer)
{

  buffer.resize(sizeof(LHCb::MDFHeader));
  LHCb::MDFHeader* mdf_header = reinterpret_cast<LHCb::MDFHeader*>(buffer.data());

  ssize_t n_bytes = input.read(&buffer[0], sizeof(LHCb::MDFHeader));
  if (n_bytes == 0) {
    cout << "Cannot read more data (Header). End-of-File reached.\n";
    return {true, true, {}, {}};
  }
  else if (n_bytes < 0) {
    cerr << "Failed to read header " << strerror(errno) << "\n";
    return {false, false, {}, {}};
  }
  unsigned header_version = mdf_header->headerVersion();
  auto hdr_size = LHCb::MDFHeader::sizeOf(header_version);
  assert((hdr_size - sizeof(LHCb::MDFHeader)) == mdf_header->subheaderLength());
  // read subheader
  buffer.resize(hdr_size + EB::Header::base_size());
  mdf_header = reinterpret_cast<LHCb::MDFHeader*>(&buffer[0]);
  n_bytes = input.read(&buffer[0] + sizeof(LHCb::MDFHeader), mdf_header->subheaderLength());
  if (n_bytes <= 0) {
    cerr << "Failed to read subheader " << strerror(errno) << "\n";
    return {false, false, {}, {}};
  }

  // read EB::Header
  char* mep_buffer = &buffer[0] + hdr_size;
  EB::Header* mep_header = reinterpret_cast<EB::Header*>(mep_buffer);
  n_bytes = input.read(mep_buffer, EB::Header::base_size());
  if (n_bytes <= 0) {
    cerr << "Failed to EB header base" << strerror(errno) << "\n";
    return {false, false, {}, {}};
  }

  buffer.resize(hdr_size + EB::Header::header_size(mep_header->n_blocks));
  mep_buffer = &buffer[0] + hdr_size;
  mep_header = reinterpret_cast<EB::Header*>(mep_buffer);
  auto data_size = static_cast<span_size_t<char const>>(mep_header->mep_size);

  buffer.resize(hdr_size + EB::Header::header_size(mep_header->n_blocks) + data_size);
  mdf_header = reinterpret_cast<LHCb::MDFHeader*>(&buffer[0]);
  mep_buffer = &buffer[0] + hdr_size;
  mep_header = reinterpret_cast<EB::Header*>(mep_buffer);

  n_bytes = input.read(
    mep_buffer + EB::Header::base_size(),
    EB::Header::header_size(mep_header->n_blocks) - EB::Header::base_size() + data_size);
  if (n_bytes <= 0) {
    cerr << "Failed to read MEP" << strerror(errno) << "\n";
    return {false, false, {}, {}};
  }

  auto total_size = EB::Header::header_size(mep_header->n_blocks) + data_size;
  return {false, true, {reinterpret_cast<char const*>(mep_buffer)}, {buffer.data() + hdr_size, total_size}};
}
