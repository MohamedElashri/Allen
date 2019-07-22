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

  vector<string> files(argc - 1);
  for (int i = 0; i < argc - 1; ++i) {
    files[i] = argv[i + 1];
  }

  MDFProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>
    provider{n_slices, events_per_slice, files};
  bool file_good = true;

  auto rs = provider.fill(0, 10);
  provider.close();
  auto vp_banks = provider.banks(BankTypes::VP, 0);

  MDFProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>
    provider_parallel{n_slices, events_per_slice, files};

  auto rp = provider_parallel.fill_parallel(0, 10);
  auto vp_banks_para = provider_parallel.banks(BankTypes::VP, 0);

  if (std::get<1>(vp_banks).size() != std::get<1>(vp_banks_para).size()) {
    cout << "different offset sizes: " << std::get<1>(vp_banks).size() << " " << std::get<1>(vp_banks_para).size() << "\n";
  } else {
    cout << std::get<1>(vp_banks).size() << " " << std::get<1>(vp_banks_para).size() << "\n";
    for (size_t i = 0; i < std::get<1>(vp_banks).size(); ++i) {
      if (std::get<1>(vp_banks)[i] != std::get<1>(vp_banks_para)[i]) {
        cout << "different offset at " << i
             << " " << std::get<1>(vp_banks)[i]
             << " " << std::get<1>(vp_banks_para)[i] << "\n";
      } else {

      }
    }
  }

  if (std::get<0>(vp_banks).size() != std::get<0>(vp_banks_para).size()) {
    cout << "different sizes: " << std::get<0>(vp_banks).size() << " " << std::get<0>(vp_banks_para).size() << "\n";
  } else {
    cout << std::get<0>(vp_banks).size() << " " << std::get<0>(vp_banks_para).size() << "\n";
    uint32_t const* banks = reinterpret_cast<uint32_t const*>(std::get<0>(vp_banks).data());
    uint32_t const* para_banks = reinterpret_cast<uint32_t const*>(std::get<0>(vp_banks_para).data());
    for (size_t i = 0; i < std::get<0>(vp_banks).size() / sizeof(uint32_t); ++i) {
      if (banks[i] != para_banks[i]) {
        cout << "different data at " << i
             << " " << banks[i]
             << " " << para_banks[i] << "\n";
      }
    }
  }

  // vector<char> buffer(110 * 1024 * 1024);

  // auto headerSize = sizeof(LHCb::MDFHeader);
  // auto* start = &buffer[0];
  // auto const* write_end = start + 100 * 1024 * 1024;
  // auto* write = &buffer[0];

  // double n_bytes = 0.;

  // Timer t;

  // std::vector<unsigned int> offsets(100000);

  // for (auto const& file : files) {
  //   ifstream input{file.c_str(), ios::binary};
  //   cout << "Opened " << file << "\n";
  //   while (!input.eof()) {
  //     input.read(write, headerSize);
  //     auto const* header = reinterpret_cast<LHCb::MDFHeader const*>(write);
  //     auto readSize = header->recordSize() - headerSize;
  //     input.read(write + headerSize, readSize);
  //     offsets[n_filled] = write + headerSize - start;
  //     write += readSize;
  //     if (write > write_end) {
  //       write = start;
  //     }
  //     ++n_filled;
  //     n_bytes += headerSize + readSize;
  //   }
  // }

  // t.stop();
  // cout << "Filled " << n_bytes / (1024 * 1024 * t.get()) << " MB/s; " << n_filled / t.get()  << " events/s\n";
}
