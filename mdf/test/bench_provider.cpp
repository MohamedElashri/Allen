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
#include <MDFProvider.h>

using namespace std;

int main(int argc, char* argv[])
{
  if (argc <= 1) {
    cout << "usage: bench_provider <file.mdf> <file.mdf> <file.mdf> ..." << endl;
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

  logger::ll.verbosityLevel = 3;

  Timer t;

  MDFProviderConfig mdf_config {false, 10, 3, 10001, 1200, 10};

  MDFProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON> mdf {
    n_slices, events_per_slice, {}, files, mdf_config};

  chrono::milliseconds sleep_interval {10};

  bool good = true, timed_out = false, done = false;
  size_t filled = 0, slice = 0;
  while (good && !done) {
    std::tie(good, done, timed_out, slice, filled) = mdf.get_slice();
    n_filled += filled;
    this_thread::sleep_for(sleep_interval);
    mdf.slice_free(slice);
  }

  t.stop();
  cout << "Filled " << n_filled / t.get() << " events/s\n";
}
