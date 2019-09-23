#include <cstring>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <unordered_set>
#include <map>
#include <cassert>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#include "raw_bank.hpp"
#include "read_mdf.hpp"
#include "eb_header.hpp"
#include "Logger.h"

using namespace std;

int main(int argc, char* argv[])
{
  if (argc != 3) {
    cout << "usage: read_mep file.mep n_mep" << endl;
    return -1;
  }

  string filename = {argv[1]};
  size_t n_meps = atol(argv[2]);

  // Some storage for reading the events into
  LHCb::MDFHeader header;
  vector<char> read_buffer(1024 * 1024, '\0');

  bool eof = false, error = false;


  int input = ::open(filename.c_str(), O_RDONLY);
  if (input != -1) {
    info_cout << "Opened " << filename << "\n";
  }
  else {
    cerr << "Failed to open file " << filename << " " << strerror(errno) << "\n";
    return -1;
  }

  vector<char> header_buffer(sizeof(LHCb::MDFHeader));
  LHCb::MDFHeader* mdf_header = reinterpret_cast<LHCb::MDFHeader*>(header_buffer.data());

  vector<char> data;

  size_t i_mep = 0;
  while (!eof && i_mep++ < n_meps) {

    ssize_t n_bytes = ::read(input, &header_buffer[0], sizeof(LHCb::MDFHeader));
    if (n_bytes <= 0) {
      cerr << "Failed to read header " << strerror(errno) << "\n";
      break;
    }
    uint header_version = mdf_header->headerVersion();
    auto hdr_size = LHCb::MDFHeader::sizeOf(header_version);
    assert((hdr_size - sizeof(LHCb::MDFHeader)) == mdf_header->subheaderLength());
    // read subheader
    header_buffer.resize(hdr_size + EB::Header::base_size());
    mdf_header = reinterpret_cast<LHCb::MDFHeader*>(&header_buffer[0]);
    auto mdf_size = mdf_header->size();
    n_bytes = ::read(input, &header_buffer[0] + sizeof(LHCb::MDFHeader), mdf_header->subheaderLength());
    if (n_bytes <= 0) {
      cerr << "Failed to read subheader " << strerror(errno) << "\n";
      break;
    }

    // check
    assert(mdf_header->size() == mdf_size);

    // read EB::Header
    char* mep_buffer = &header_buffer[0] + hdr_size;
    EB::Header* mep_header = reinterpret_cast<EB::Header*>(mep_buffer);

    n_bytes = ::read(input, mep_buffer, EB::Header::base_size());
    if (n_bytes <= 0) {
      cerr << "Failed to EB header base" << strerror(errno) << "\n";
      break;
    }
    cout << mep_header->version << " " << mep_header->n_blocks << " " << mep_header->mep_size << "\n";

    header_buffer.resize(hdr_size + EB::Header::header_size(mep_header->n_blocks));
    mdf_header = reinterpret_cast<LHCb::MDFHeader*>(&header_buffer[0]);
    mep_buffer = &header_buffer[0] + hdr_size;
    mep_header = reinterpret_cast<EB::Header*>(mep_buffer);

    n_bytes = ::read(input, mep_buffer + EB::Header::base_size(),
                     EB::Header::header_size(mep_header->n_blocks) - EB::Header::base_size());
    if (n_bytes <= 0) {
      cerr << "Failed to EB header" << strerror(errno) << "\n";
      break;
    }
    EB::Header full_header{reinterpret_cast<char const*>(mep_buffer)};

    auto data_size = full_header.mep_size;
    data.resize(data_size);
    cout << "data size " << data_size << "\n";
    n_bytes = ::read(input, &data[0], data_size);
    if (n_bytes <= 0) {
      cerr << "Failed to read data of size " << mdf_header->size() << " " << strerror(errno) << "\n";
      break;
    }

    gsl::span<char const> data_span{data.data(), data_size};
    auto const* d = data_span.begin();
    size_t i_block = 0;
    while(d != data_span.end()) {
      EB::BlockHeader const block_header{d};
      char const* block_data = d + block_header.header_size(block_header.n_frag);
      char const* block_end = block_data + block_header.block_size;

      assert(d - data_span.begin() == full_header.offsets[i_block]);

      cout << "fragment"
           << " packing: " << std::setw(4) << block_header.n_frag
           << " event_id: " << std::setw(6) << block_header.event_id
           << " type: " << std::setw(3) << int(block_header.types[0])
           << " source_id " << std::setw(4) << full_header.source_ids[i_block]
           << " version: " << std::setw(2) << full_header.versions[i_block]
           << " size: " << std::setw(6) << block_header.block_size
           << "\n";

      d = block_end;
      ++i_block;
    }
  }

  return 0;
}
