#include <cstring>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <unordered_set>
#include <map>

#include "raw_bank.hpp"
#include "read_mdf.hpp"
#include "Tools.h"
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
  size_t events_per_slice = 1000;
  size_t n_filled = 0;

  vector<string> files(argc - 1);
  for (int i = 0; i < argc - 1; ++i) {
    files[i] = argv[i + 1];
  }

  MDFProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>
    provider{n_slices, events_per_slice, std::move(files)};
  bool file_good = true;

  while(file_good) {
    auto r = provider.fill(0, 1000);
    file_good = std::get<0>(r);
    n_filled += std::get<2>(r);
  }
  cout << "Filled " << n_filled << " events\n";
}
