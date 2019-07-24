#include <cstring>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <unordered_set>
#include <map>

#include <raw_bank.hpp>
#include <read_mdf.hpp>
#include <Timer.h>
#include <Tools.h>
#include <MDFProvider.h>

using namespace std;

int main(int argc, char* argv[])
{
  if (argc <= 1) {
    cout << "usage: test_read <file.mdf> <file.mdf> <file.mdf> ..." << endl;
    return -1;
  }

  string filename = {argv[1]};
  size_t n_slices = 10;
  size_t events_per_slice = 100;
  double n_filled = 0;
  size_t n_bytes = 0;

  vector<string> files(argc - 1);
  for (int i = 0; i < argc - 1; ++i) {
    files[i] = argv[i + 1];
  }

  // vector<char> buffer(110 * 1024 * 1024);

  // auto headerSize = sizeof(LHCb::MDFHeader);
  // auto* start = &buffer[0];
  // auto const* write_end = start + 100 * 1024 * 1024;
  // auto* write = &buffer[0];

  // double n_bytes = 0.;

  Timer t;

  vector<char> buffer(1024 * 1024);
  vector<char> decompression_buffer(1024 * 1024);
  gsl::span<char> buffer_span{buffer};

  LHCb::MDFHeader header;

  for (auto const& file : files) {
    cout << "Opened " << file << "\n";
    ifstream input{file.c_str(), ios::binary};
    bool eof = false;
    while (!eof) {
      ++n_filled;
      auto r = MDF::read_event(input, header, buffer_span, decompression_buffer, false);
      n_bytes += std::get<2>(r).size() + sizeof(header);
      eof = std::get<0>(r);
    }
  }

  t.stop();
  cout << "Filled " << n_filled << " events; " << n_bytes / (1024 * 1024)  << " MB\n";
  cout << "Filled " << n_bytes / (1024 * 1024 * t.get()) << " MB/s; " << n_filled / t.get()  << " events/s\n";
}
