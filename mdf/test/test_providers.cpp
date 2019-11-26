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
  MDFProviderConfig mdf_config {true, 2, 1};

  unique_ptr<MDFProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>> mdf;
  unique_ptr<BinaryProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>> binary;

  size_t slice_mdf = 0, slice_binary = 0;
  size_t filled_mdf = 0, filled_binary = 0;
} // namespace

int main(int argc, char* argv[])
{

  Catch::Session session; // There must be exactly one instance

  string directory;

  // Build a new parser on top of Catch's
  using namespace Catch::clara;
  auto cli = session.cli()                          // Get Catch's composite command line parser
             | Opt(directory, string {"directory"}) // bind variable to a new option, with a hint string
                 ["--directory"]("input directory") |
             Opt(s_config.n_events, string {"#events"}) // bind variable to a new option, with a hint string
               ["--nevents"]("number of events");

  // Now pass the new composite back to Catch so it uses that
  session.cli(cli);

  // Let Catch (using Clara) parse the command line
  int returnCode = session.applyCommandLine(argc, argv);
  if (returnCode != 0) {
    return returnCode;
  }

  s_config.run = !directory.empty();
  if (s_config.run) {
    for (auto file : list_folder(directory + "/banks/mdf", "mdf")) {
      s_config.mdf_files.push_back(directory + "/banks/mdf/" + file);
    }
  }
  for (auto sd : {string {"UT"}, string {"VP"}, string {"FTCluster"}, string {"Muon"}}) {
    s_config.banks_dirs.push_back(directory + "/banks/" + sd);
  }

  if (s_config.run) {
    // Allocate providers and get slices
    mdf = make_unique<MDFProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>>(
      s_config.n_slices, s_config.n_events, s_config.n_events, s_config.mdf_files, mdf_config);

    bool good = false, timed_out = false, done = false;
    std::tie(good, done, timed_out, slice_mdf, filled_mdf) = mdf->get_slice();
    auto const& events_mdf = mdf->event_ids(slice_mdf);

    binary = make_unique<BinaryProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON>>(
      s_config.n_slices, s_config.n_events, s_config.n_events, s_config.banks_dirs, false, std::nullopt, events_mdf);

    std::tie(good, done, timed_out, slice_binary, filled_binary) = binary->get_slice();
  }

  return session.run();
}

template<BankTypes BT_>
struct BTTag {
  inline static const BankTypes BT = BT_;
};

/**
 * @brief      Check bank or offset data
 */
template<size_t I>
void check_banks(BanksAndOffsets const& left, BanksAndOffsets const& right)
{
  static_assert(I < tuple_size_v<BanksAndOffsets>);
  REQUIRE(std::get<I>(left).size() == std::get<I>(right).size());
  for (size_t i = 0; i < std::get<I>(left).size(); ++i) {
    REQUIRE(std::get<I>(left)[i] == std::get<I>(right)[i]);
  }
}

// Main test case, multiple bank types are checked
TEMPLATE_TEST_CASE(
  "MDF versus Binary",
  "[MDF binary]",
  BTTag<BankTypes::VP>,
  BTTag<BankTypes::UT>,
  BTTag<BankTypes::FT>,
  BTTag<BankTypes::MUON>)
{

  if (!s_config.run) return;

  // Check that the number of events read matches
  REQUIRE(filled_binary == filled_mdf);

  // Get the events
  auto const& events_mdf = mdf->event_ids(slice_mdf);
  auto const& events_binary = binary->event_ids(slice_binary);

  // Check that the events match
  SECTION("Checking Event IDs")
  {
    REQUIRE(events_mdf.size() == events_binary.size());
    for (size_t i = 0; i < events_mdf.size(); ++i) {
      auto [run_mdf, event_mdf] = events_mdf[i];
      auto [run_binary, event_binary] = events_binary[i];
      REQUIRE(run_mdf == run_binary);
      REQUIRE(event_mdf == event_binary);
    }
  }

  // Get the banks
  auto banks_mdf = mdf->banks(TestType::BT, slice_mdf);
  auto banks_binary = binary->banks(TestType::BT, slice_binary);

  SECTION("Checking offsets") { check_banks<1>(banks_mdf, banks_binary); }

  SECTION("Checking data") { check_banks<0>(banks_mdf, banks_binary); }
}
