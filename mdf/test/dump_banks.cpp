#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <unordered_set>
#include <map>
#include <dirent.h>
#include <sys/stat.h>
#include <cerrno>
#include <cstring>

#include "Event/RawBank.h"
#include "read_mdf.hpp"

namespace {
  using std::cerr;
  using std::cout;
  using std::endl;
  using std::ifstream;
  using std::ios;
  using std::make_pair;
  using std::map;
  using std::string;
  using std::to_string;
  using std::unordered_set;
  using std::vector;
} // namespace

int main(int argc, char* argv[])
{
  if (argc <= 2) {
    cout << "usage: dump_banks <file.mdf> <output_dir>" << endl;
    return -1;
  }

  vector<string> files = {{argv[1]}};
  string output_dir = {argv[2]};

  // Make output directory if needed
  vector<string> directories;
  auto pos = output_dir.find("/");
  while (pos != string::npos) {
    auto first = string {output_dir}.substr(0, pos);
    directories.push_back(first);
    output_dir = output_dir.substr(pos + 1, string::npos);
    pos = output_dir.find("/");
  }
  if (!output_dir.empty()) {
    directories.push_back(output_dir);
  }

  output_dir = "";
  for (auto dir : directories) {
    output_dir = output_dir.empty() ? dir : output_dir + "/" + dir;
    auto* d = opendir(output_dir.c_str());
    if (d) {
      closedir(d);
    }
    else {
      const int status = mkdir(output_dir.c_str(), S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
      if (status != 0 && errno != EEXIST) {
        cerr << "Error creating directory " << output_dir << endl;
        cerr << std::strerror(errno) << endl;
        return status;
      }
    }
  }

  unordered_set<BankTypes> types = {BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN};

  size_t n_read = 0;
  Allen::buffer_map buffers;
  vector<LHCb::ODIN> odins;
  std::tie(n_read, buffers, odins) = MDF::read_events(10, files, types);
  for (const auto& odin : odins) {
    cout << odin.runNumber() << " " << odin.eventNumber() << " " << odin.triggerConfigurationKey() << endl;
  }

  for (auto type : types) {
    auto dir = output_dir + "/" + bank_name(type);
    const int status = mkdir(dir.c_str(), S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
    if (status != 0 && errno != EEXIST) {
      cerr << "Error creating directory " << output_dir << endl;
      cerr << std::strerror(errno) << endl;
      return status;
    }
  }

  for (const auto& entry : buffers) {
    cout << entry.second.first.size() << " " << entry.second.second.back() << endl;

    const auto& buf = entry.second.first;
    const auto& offsets = entry.second.second;
    for (size_t i = 0; i < offsets.size() - 1; ++i) {
      const auto& odin = odins[i];

      string filename =
        (output_dir + "/" + bank_name(entry.first) + "/" + to_string(odin.runNumber()) + "_" +
         to_string(odin.eventNumber()) + ".bin");
      std::ofstream outfile {filename.c_str(), ios::out | ios::binary};
      outfile.write(buf.data() + offsets[i], offsets[i + 1] - offsets[i]);
      outfile.close();
    }
  }

  cout << "read " << n_read << " events" << endl;
}
