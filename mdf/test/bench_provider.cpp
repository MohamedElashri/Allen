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

  Timer t;

  MDFProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>
    mdf{n_slices, events_per_slice, files};

  chrono::milliseconds sleep_interval{std::lround(1.f/70.f * 1000.f)};

  bool error = false, good = true;
  size_t filled = 0;
  size_t i = 0;
  while (good || filled != 0) {
    std::tie(good, filled) = mdf.fill_parallel((++i) % n_slices, events_per_slice);
    n_filled += filled;
    this_thread::sleep_for(sleep_interval);
  }

  t.stop();
  cout << "Filled " << n_filled / t.get()  << " events/s\n";
}
