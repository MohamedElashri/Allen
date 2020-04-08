#include <cstring>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <unordered_set>
#include <map>

#include <Event/RawBank.h>
#include <Timer.h>
#include <MEPProvider.h>

using namespace std;

int main(int argc, char* argv[])
{
  if (argc <= 1) {
    cout << "usage: bench_provider <file.mep> <file.mep> <file.mep> ..." << endl;
    return -1;
  }

  string filename = {argv[1]};
  size_t n_slices = 10;
  size_t events_per_slice = 1000;
  double n_filled = 0.;

  vector<string> files(argc - 1);
  for (int i = 0; i < argc - 1; ++i) {
    files[i] = argv[i + 1];
  }

  logger::setVerbosity(4);

  Timer t;

  MEPProviderConfig config {false,         // verify MEP checksums
                            10,            // number of read buffers
                            2,             // number of transpose threads
                            4,             // MPI sliding window size
                            false,         // Receive from MPI or read files
                            false,         // Run the application non-stop
                            true,          // Transpose MEP
                            {{"mem", 0}}}; // mapping of receiver to its numa node

  MEPProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON> mep {
    n_slices, events_per_slice, {}, files, config};

  chrono::milliseconds sleep_interval {10};

  bool good = true, done = false, timed_out = false;
  size_t filled = 0, slice = 0;
  while (good || filled != 0) {
    std::tie(good, done, timed_out, slice, filled) = mep.get_slice();
    n_filled += filled;
    this_thread::sleep_for(sleep_interval);
    mep.slice_free(slice);
  }

  t.stop();
  cout << "Filled " << n_filled / t.get() << " events/s\n";
}
