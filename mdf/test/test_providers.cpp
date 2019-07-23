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
#include <InputTools.h>
#include <MDFProvider.h>
#include <BinaryProvider.h>

#define CATCH_CONFIG_RUNNER
#include <catch.hpp>

using namespace std;

struct Config {
  vector<string> banks_dirs;
  vector<string> mdf_files;
  size_t n_slices = 1;
  size_t n_events = 10;
  size_t events_per_slice = 100;
  bool run = false;
};

namespace {
  Config s_config;
}

int main(int argc, char* argv[])
{

  Catch::Session session; // There must be exactly one instance

  string directory;
  // Build a new parser on top of Catch's
  using namespace Catch::clara;
  auto cli
    = session.cli() // Get Catch's composite command line parser
    | Opt(directory, string{"directory"}) // bind variable to a new option, with a hint string
         ["--directory"]
         ("input directory");

  // Now pass the new composite back to Catch so it uses that
  session.cli(cli);

  // Let Catch (using Clara) parse the command line
  int returnCode = session.applyCommandLine( argc, argv );
  if( returnCode != 0 ) {
      return returnCode;
  }

  s_config.run = !directory.empty();
  for (auto file : list_folder(directory + "/banks/mdf", "mdf")) {
    s_config.mdf_files.push_back(directory + "/banks/mdf/" + file);
  }
  for (auto sd : {string{"UT"}, string{"VP"}, string{"FTCluster"}, string{"Muon"}}) {
    s_config.banks_dirs.push_back(directory + "/banks/" + sd);
  }

  return session.run();
}

template<size_t I>
void check_banks(BanksAndOffsets const& left, BanksAndOffsets const& right) {
  static_assert(I < tuple_size_v<BanksAndOffsets>);
  REQUIRE(std::get<I>(left).size() == std::get<I>(right).size());
  for (size_t i = 0; i < std::get<I>(left).size(); ++i) {
    REQUIRE(std::get<I>(left)[i] == std::get<I>(right)[i]);
  }
}

TEST_CASE( "MDF versus Binary", "[compare_MDF_binary]" ) {

  if (!s_config.run) return;

  MDFProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>
    mdf{s_config.n_slices, s_config.events_per_slice, s_config.mdf_files};

  size_t const slice = 0;
  mdf.fill(slice, s_config.n_events);
  auto banks_mdf = mdf.banks(BankTypes::VP, slice);

  BinaryProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>
    binary{s_config.n_slices, s_config.events_per_slice, s_config.banks_dirs};

  binary.fill(slice, s_config.n_events);
  auto banks_binary = binary.banks(BankTypes::VP, slice);

  check_banks<0>(banks_mdf, banks_binary);
  check_banks<1>(banks_mdf, banks_binary);
}

TEST_CASE( "MDF versus Parallel MDF", "[compare_MDF_parallel]" ) {

  if (!s_config.run) return;

  MDFProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>
    mdf{s_config.n_slices, s_config.events_per_slice, s_config.mdf_files};

  size_t const slice = 0;
  mdf.fill(slice, s_config.n_events);
  auto banks_mdf = mdf.banks(BankTypes::VP, slice);

  MDFProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>
    parallel{s_config.n_slices, s_config.events_per_slice, s_config.mdf_files};

  parallel.fill_parallel(slice, s_config.n_events);
  auto banks_para = parallel.banks(BankTypes::VP, slice);

  check_banks<0>(banks_mdf, banks_para);
  check_banks<1>(banks_mdf, banks_para);
}
