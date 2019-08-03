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
  bool run = false;
};

namespace {
  Config s_config;
  MDFProviderConfig mdf_config{true};
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
         ("input directory")
    | Opt(s_config.n_events, string{"#events"}) // bind variable to a new option, with a hint string
         ["--nevents"]
         ("number of events");

  // Now pass the new composite back to Catch so it uses that
  session.cli(cli);

  // Let Catch (using Clara) parse the command line
  int returnCode = session.applyCommandLine( argc, argv );
  if( returnCode != 0 ) {
      return returnCode;
  }

  s_config.run = !directory.empty();
  if (s_config.run) {
    for (auto file : list_folder(directory + "/banks/mdf", "mdf")) {
      s_config.mdf_files.push_back(directory + "/banks/mdf/" + file);
    }
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
    mdf{s_config.n_slices, s_config.n_events, s_config.n_events, s_config.mdf_files, mdf_config};

  auto [good, timed_out, mdf_slice, mdf_filled] = mdf.get_slice();
  auto banks_mdf = mdf.banks(BankTypes::VP, mdf_slice);
  auto const& events_mdf = mdf.event_ids(mdf_slice);

  BinaryProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>
    binary{s_config.n_slices, s_config.n_events, s_config.n_events, s_config.banks_dirs,
           false, events_mdf};

  size_t binary_slice = 0, binary_filled = 0;
  std::tie(good, timed_out, binary_slice, binary_filled) = binary.get_slice();
  auto banks_binary = binary.banks(BankTypes::VP, binary_slice);
  auto const& events_binary = binary.event_ids(binary_slice);

  REQUIRE(binary_filled == mdf_filled);

  SECTION("Checking Event IDs") {
    REQUIRE(events_mdf.size() == events_binary.size());
    for (size_t i = 0; i < events_mdf.size(); ++i) {
      auto [run_mdf, event_mdf] = events_mdf[i];
      auto [run_binary, event_binary] = events_binary[i];
      REQUIRE(run_mdf == run_binary);
      REQUIRE(event_mdf == event_binary);
    }
  }

  SECTION("Checking offsets") {
    check_banks<1>(banks_mdf, banks_binary);
  }

  SECTION("Checking data") {
    check_banks<0>(banks_mdf, banks_binary);
  }
}
