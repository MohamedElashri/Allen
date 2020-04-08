#include <cstring>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <unordered_set>
#include <map>

#include <Event/RawBank.h>
#include <read_mdf.hpp>
#include <read_mep.hpp>
#include <Timer.h>
#include <InputTools.h>
#include <MDFProvider.h>
#include <BinaryProvider.h>
#include <TransposeMEP.h>

#define CATCH_CONFIG_RUNNER
#include <catch.hpp>

using namespace std;
using namespace std::string_literals;

struct Config {
  vector<string> banks_dirs;
  vector<string> mdf_files;
  vector<string> mep_files;
  size_t n_slices = 1;
  size_t n_events = 10;
  bool run = false;
};

namespace {
  Config s_config;
  MDFProviderConfig mdf_config {true, 2, 1};

  unique_ptr<MDFProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN>> mdf;
  unique_ptr<BinaryProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN>> binary;

  size_t slice_mdf = 0, slice_binary = 0;
  size_t filled_mdf = 0, filled_binary = 0;

  vector<char> mep_buffer;
  Slices mep_slices;
  EventIDs events_mep;
  std::vector<int> ids;
  std::array<unsigned int, LHCb::RawBank::LastType> banks_count;
} // namespace

BanksAndOffsets mep_banks(Slices& slices, BankTypes bank_type, size_t slice_index)
{
  auto ib = to_integral<BankTypes>(bank_type);
  auto const& [banks, banks_size, offsets, offsets_size] = slices[ib][slice_index];
  span<char const> b {banks[0].data(), offsets[offsets_size - 1]};
  span<unsigned int const> o {offsets.data(), static_cast<::offsets_size>(offsets_size)};
  return BanksAndOffsets {{std::move(b)}, offsets[offsets_size - 1], std::move(o)};
}

size_t transpose_mep(
  Slices& mep_slices,
  int output_index,
  EB::Header& mep_header,
  gsl::span<char const> mep_data,
  size_t chunk_size)
{

  bool success = false;
  std::tie(success, banks_count) = MEP::fill_counts(mep_header, mep_data);
  ids = bank_ids();

  // read MEP
  std::vector<std::vector<uint32_t>> input_offsets(mep_header.n_blocks);
  for (auto& offsets : input_offsets) {
    offsets.resize(mep_header.packing_factor + 1);
  }

  std::vector<std::tuple<EB::BlockHeader, gsl::span<char const>>> blocks(mep_header.n_blocks);

  MEP::find_blocks(mep_header, mep_data, blocks);

  MEP::fragment_offsets(blocks, input_offsets);

  auto r = MEP::transpose_events(
    mep_slices, output_index, ids, banks_count, events_mep, mep_header, blocks, input_offsets, {0, chunk_size});
  return std::get<2>(r);
}

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
    for (auto [ext, dir] : {std::tuple {string {"mdf"}, std::ref(s_config.mdf_files)},
                            std::tuple {string {"mep"}, std::ref(s_config.mep_files)}}) {
      for (auto file : list_folder(directory + "/banks/" + ext, ext)) {
        dir.get().push_back(directory + "/banks/" + ext + "/" + file);
      }
    }
  }
  for (auto sd : {"UT"s, "VP"s, "FTCluster"s, "Muon"s, "ODIN"s}) {
    s_config.banks_dirs.push_back(directory + "/banks/" + sd);
  }

  if (s_config.run) {
    // Allocate providers and get slices
    mdf = make_unique<MDFProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN>>(
      s_config.n_slices, s_config.n_events, s_config.n_events, s_config.mdf_files, mdf_config);

    bool good = false, timed_out = false, done = false;
    std::tie(good, done, timed_out, slice_mdf, filled_mdf) = mdf->get_slice();
    auto const& events_mdf = mdf->event_ids(slice_mdf);

    binary = make_unique<BinaryProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN>>(
      s_config.n_slices, s_config.n_events, s_config.n_events, s_config.banks_dirs, false, std::nullopt, events_mdf);

    std::tie(good, done, timed_out, slice_binary, filled_binary) = binary->get_slice();
  }

  if (s_config.run) {
    auto input = MDF::open(s_config.mep_files[0], O_RDONLY);
    info_cout << "Opened " << s_config.mep_files[0] << "\n";

    // Transpose MEP
    auto [eof, success, mep_header, mep_span] = MEP::read_mep(input, mep_buffer);

    auto pf = mep_header.packing_factor;
    auto size_fun = [pf](BankTypes) -> std::tuple<size_t, size_t> {
      return {std::lround(average_event_size * pf * bank_size_fudge_factor * kB), pf};
    };
    mep_slices =
      allocate_slices<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN>(1, size_fun);

    transpose_mep(mep_slices, 0, mep_header, mep_span, s_config.n_events);
  }

  return session.run();
}

template<BankTypes BT_>
struct BTTag {
  inline static const BankTypes BT = BT_;
};

/**
 * @brief      Check offsets
 */
void check_offsets(BanksAndOffsets const& left, BanksAndOffsets const& right)
{
  REQUIRE(std::get<2>(left).size() == std::get<2>(right).size());
  for (::offsets_size i = 0; i < std::get<2>(left).size(); ++i) {
    REQUIRE(std::get<2>(left)[i] == std::get<2>(right)[i]);
  }
}

/**
 * @brief      Check bank spans
 */
void check_banks(BanksAndOffsets const& left, BanksAndOffsets const& right)
{
  // data size
  REQUIRE(std::get<1>(left) == std::get<1>(right));

  auto const& lb = std::get<0>(left);
  auto const& rb = std::get<0>(right);

  // spans
  REQUIRE(lb.size() == rb.size());
  for (size_t i = 0; i < lb.size(); ++i) {
    REQUIRE(lb[i].size() == rb[i].size());
    for (::events_size j = 0; j < lb[i].size(); ++j) {
      REQUIRE(lb[i][j] == rb[i][j]);
    }
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

  SECTION("Checking offsets") { check_offsets(banks_mdf, banks_binary); }

  SECTION("Checking data") { check_banks(banks_mdf, banks_binary); }
}

// Main test case, multiple bank types are checked
TEMPLATE_TEST_CASE(
  "Binary vs MEP",
  "[MEP binary]",
  BTTag<BankTypes::VP>,
  BTTag<BankTypes::UT>,
  BTTag<BankTypes::FT>,
  BTTag<BankTypes::MUON>)
{

  if (!s_config.run) return;

  // Get the events
  auto const& events_binary = binary->event_ids(slice_binary);

  // Check that the events match
  SECTION("Checking Event IDs")
  {
    REQUIRE(events_mep.size() == events_binary.size());
    for (size_t i = 0; i < events_mep.size(); ++i) {
      auto [run_mep, event_mep] = events_mep[i];
      auto [run_binary, event_binary] = events_binary[i];
      REQUIRE(run_mep == run_binary);
      REQUIRE(event_mep == event_binary);
    }
  }

  // Get the banks
  auto banks_mep = mep_banks(mep_slices, TestType::BT, 0);
  auto banks_binary = binary->banks(TestType::BT, slice_binary);

  SECTION("Checking offsets") { check_offsets(banks_mep, banks_binary); }

  SECTION("Checking data") { check_banks(banks_mep, banks_binary); }
}
