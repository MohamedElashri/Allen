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

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#include "Event/RawBank.h"
#include "read_mdf.hpp"
#include "sourceid.h"

using namespace std;

int main(int argc, char* argv[])
{
  if (argc != 3) {
    cout << "usage: test_read file.mdf n_events" << endl;
    return -1;
  }

  string filename = {argv[1]};
  size_t n_events = atol(argv[2]);

  // Some storage for reading the events into
  LHCb::MDFHeader header;
  vector<char> read_buffer(1024 * 1024, '\0');
  vector<char> decompression_buffer(1024 * 1024, '\0');

  bool eof = false, error = false;

  gsl::span<const char> bank_span;

  auto input = MDF::open(filename.c_str(), O_RDONLY);
  if (input.good) {
    cout << "Opened " << filename << "\n";
  }
  else {
    cerr << "Failed to open file " << filename << " " << strerror(errno) << "\n";
    return -1;
  }

  size_t i_event = 0;
  while (!eof && i_event++ < n_events) {

    std::tie(eof, error, bank_span) = MDF::read_event(input, header, read_buffer, decompression_buffer, true, true);
    if (eof || error) {
      return -1;
    }

    array<size_t, LHCb::RawBank::LastType + 1> bank_counts {0};

    unsigned header_size = header.size();

    unsigned bank_total_size = 0;
    // Put the banks in the event-local buffers
    char const* bank = bank_span.data();
    char const* end = bank_span.data() + bank_span.size();
    while (bank < end) {
      const auto* b = reinterpret_cast<const LHCb::RawBank*>(bank);
      if (b->magic() != LHCb::RawBank::MagicPattern) {
        cout << "magic pattern failed: " << std::hex << b->magic() << std::dec << endl;
        goto error;
      }

      auto const source_id = b->sourceID();
      std::string det = SourceId_sysstr(source_id);
      std::string fill(7 - det.size(), ' ');

      if (b->type() < LHCb::RawBank::LastType) {
        ++bank_counts[b->type()];
        cout << "bank: " << std::setw(16) << b->type() << " version " << std::setw(2) << b->version()
             << " sourceID: " << std::setw(6) << b->sourceID() << " top5: " << std::setw(2) << SourceId_sys(source_id)
             << fill << " (" << det << ") " << std::setw(5) << SourceId_num(source_id) << " " << std::setw(5)
             << b->totalSize() << "\n";
      }
      else {
        ++bank_counts[LHCb::RawBank::LastType];
      }

      // Move to next raw bank
      bank += b->totalSize();
      if (b->type() != LHCb::RawBank::DAQ) {
        bank_total_size += b->totalSize();
      }
    }

    cout << "Event " << std::setw(7) << i_event << "; header size: " << header_size
         << "; bank total size: " << bank_total_size << "\n";
    cout << "Type | #Banks\n";
    for (size_t i = 0; i < bank_counts.size(); ++i) {
      if (bank_counts[i] != 0) {
        cout << std::setw(4) << i << " | " << std::setw(6) << bank_counts[i] << "\n";
      }
    }
    cout << "\n";
  }

error:
  input.close();
}
