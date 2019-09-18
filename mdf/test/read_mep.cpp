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
    cout << "usage: test_read file.mdf n_mep" << endl;
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

  char header_buffer[100];
  LHCb::MDFHeader* mdf_header = reinterpret_cast<LHCb::MDFHeader*>(header_buffer);

  vector<char> data;

  size_t i_mep = 0;
  while (!eof && i_mep++ < n_meps) {

    ssize_t n_bytes = ::read(input, header_buffer, sizeof(LHCb::MDFHeader));
    if (n_bytes <= 0) {
      cerr << "Failed to read header " << strerror(errno) << "\n";
      break;
    }
    uint header_version = mdf_header->headerVersion();
    auto hdr_size = LHCb::MDFHeader::sizeOf(header_version);
    assert((hdr_size - sizeof(LHCb::MDFHeader)) == mdf_header->subheaderLength());
    // read subheader
    n_bytes = ::read(input, header_buffer + sizeof(LHCb::MDFHeader), mdf_header->subheaderLength());
    if (n_bytes <= 0) {
      cerr << "Failed to read subheader " << strerror(errno) << "\n";
      break;
    }

    auto data_size = mdf_header->size();
    data.resize(data_size);
    n_bytes = ::read(input, &data[0], data_size);
    if (n_bytes <= 0) {
      cerr << "Failed to read data of size " << mdf_header->size() << " " << strerror(errno) << "\n";
      break;
    }

    gsl::span<char const> data_span{data.data(), data_size};
    auto const* d = data_span.begin();
    cout << "data size " << data_size << "\n";
    while(d != data_span.end()) {
      auto eb_header = reinterpret_cast<EB::Header const*>(d);
      EB::BlockHeader const block_header{d + sizeof(EB::Header)};
      char const* fragment_data = d + sizeof(EB::Header) + block_header.header_size(block_header.n_frag);
      char const* fragment_end = fragment_data + block_header.block_size;

      cout << "fragment source_id " << std::setw(4) << eb_header->source_id
           << " version: " << std::setw(2) << eb_header->version
           << " event_id: " << std::setw(6) << block_header.event_id
           << " packing: " << std::setw(4) << block_header.n_frag
           << " size: " << std::setw(5) << block_header.block_size
           << " type: " << std::setw(3) << int(block_header.types[0]);
      for (size_t i = 0; i < block_header.n_frag; ++i) {
        cout << " bsize " << std::setw(3) << i << ": " << std::setw(4) << block_header.sizes[i];
      }
      cout << std::setw(10) << fragment_end - data_span.data();
      cout << "\n";

      d = fragment_end;
    }

  }

  return 0;
}
