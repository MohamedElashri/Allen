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

#include <raw_bank.hpp>
#include <read_mdf.hpp>
#include <Timer.h>

using namespace std;

int main(int argc, char* argv[])
{
  if (argc <= 1) {
    cout << "usage: bench_read <file.mdf> <file.mdf> <file.mdf> ..." << endl;
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

  Timer t;

  vector<char> buffer(100 * 1024 * 1024);
  vector<char> decompression_buffer(1024 * 1024);
  size_t offset = 0;

  LHCb::MDFHeader header;

  for (auto const& file : files) {
    int input = ::open(file.c_str(), O_RDONLY);
    if (input < 0) {
      cerr << "Failed to open " << file << " " << strerror(errno) << "\n";
    }
    else {
      cout << "Opened " << file << "\n";
    }
    bool eof = false;
    while (!eof) {

      gsl::span<char> buffer_span {buffer.data() + offset, buffer.size() - offset};

      ++n_filled;
      auto r = MDF::read_event(input, header, buffer_span, decompression_buffer, false);
      size_t event_size = std::get<2>(r).size() + sizeof(header);
      n_bytes += event_size;
      eof = std::get<0>(r);
      offset += event_size;
      if (buffer.size() - offset < 2 * 1024 * 1024) {
        offset = 0;
      }
    }
    ::close(input);
  }

  t.stop();
  cout << "Filled " << n_filled << " events; " << n_bytes / (1024 * 1024) << " MB\n";
  cout << "Filled " << n_bytes / (1024 * 1024 * t.get()) << " MB/s; " << n_filled / t.get() << " events/s\n";
}
