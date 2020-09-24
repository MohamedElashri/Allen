/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <cstring>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <unordered_set>
#include <map>

#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <Event/RawBank.h>
#include <mdf_header.hpp>
#include <read_mdf.hpp>
#include <Timer.h>
#include <Common.h>

using namespace std;

int main(int argc, char* argv[])
{
  if (argc <= 1) {
    cout << "usage: bench_read <file.mdf> <file.mdf> <file.mdf> ..." << endl;
    return -1;
  }

  double n_filled = 0;
  size_t n_bytes = 0;

  vector<string> files(argc - 1);
  for (int i = 0; i < argc - 1; ++i) {
    files[i] = argv[i + 1];
  }

  Timer t;

  vector<char> buffer(100 * 1024 * 1024);
  vector<char> decompression_buffer(1024 * 1024);
  size_t offset = 0;

  LHCb::MDFHeader header;
  bool success = true;

  for (auto const& file : files) {
    auto input = MDF::open(file, O_RDONLY);
    if (!input.good) {
      cerr << "Failed to open " << file << " " << strerror(errno) << "\n";
      success = false;
      break;
    }
    else {
      cout << "Opened " << file << "\n";
    }
    bool eof = false;
    while (!eof) {

      gsl::span<char> buffer_span {buffer.data() + offset, static_cast<::events_size>(buffer.size() - offset)};

      ++n_filled;
      auto r = MDF::read_event(input, header, buffer_span, decompression_buffer, false);
      size_t event_size = std::get<2>(r).size() + LHCb::MDFHeader::sizeOf(3);
      n_bytes += event_size;
      eof = std::get<0>(r);
      offset += event_size;
      if (buffer.size() - offset < 2 * 1024 * 1024) {
        offset = 0;
      }
    }
    input.close();
  }

  if (success) {
    t.stop();
    cout << "Filled " << n_filled << " events; " << n_bytes / (1024 * 1024) << " MB\n";
    cout << "Filled " << n_bytes / (1024 * 1024 * t.get()) << " MB/s; " << n_filled / t.get() << " events/s\n";
  }
  return success ? 0 : -1;
}
