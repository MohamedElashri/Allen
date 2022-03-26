/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include <cstring>
#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <unordered_set>
#include <map>
#include <filesystem>

#include <Event/RawBank.h>
#include <read_mdf.hpp>
#include <Timer.h>
#include <InputTools.h>
#include <MDFProvider.h>
#include <TransposeTypes.h>
#include <Transpose.h>

#ifdef USE_BOOST_FILESYSTEM
#include <boost/filesystem.hpp>
#else
#include <filesystem>
#endif

#define CATCH_CONFIG_RUNNER
#include <catch2/catch.hpp>

#ifdef USE_BOOST_FILESYSTEM
namespace fs = boost::filesystem;
#else
namespace fs = std::filesystem;
#endif

using namespace std;
using namespace std::string_literals;

struct Config {
  vector<string> mdf_files;
  size_t n_slices = 2;
  size_t n_events = 5;
  bool run = false;
};

namespace {
  Config s_config;
} // namespace

std::tuple<bool, Allen::sd_from_raw_bank, Allen::bank_sorter> file_type(gsl::span<char const> bank_data)
{
  auto is_mc = check_sourceIDs(bank_data);
  Allen::sd_from_raw_bank sd_from_raw;
  Allen::bank_sorter sorter;
  if (is_mc) {
    sd_from_raw = sd_from_bank_type;
    sorter = sort_by_bank_type;
  }
  else {
    sd_from_raw = sd_from_sourceID;
    sorter = sort_by_sourceID;
  }
  return {is_mc, std::move(sd_from_raw), std::move(sorter)};
}

std::tuple<bool, std::array<unsigned, NBankTypes>, std::vector<LHCb::ODIN>, size_t, size_t, size_t, size_t>
mdf_read_sizes(std::string filename, std::unordered_set<BankTypes> const& bank_types, size_t min_events)
{
  // Storage for the sizes
  std::array<std::vector<size_t>, NBankTypes> sizes;
  for (auto bt : bank_types) {
    sizes[to_integral(bt)].push_back(0);
  }

  std::array<unsigned, NBankTypes> banks_count;
  banks_count.fill(0);

  // Some storage for reading the events into
  LHCb::MDFHeader header;
  vector<char> read_buffer(1024 * 1024, '\0');
  vector<char> decompression_buffer(1024 * 1024, '\0');
  std::vector<LHCb::ODIN> odins;

  bool eof = false, error = false;

  gsl::span<const char> bank_span;

  size_t total_size = 0;

  auto input = MDF::open(filename.c_str(), O_RDONLY);
  if (input.good) {
    cout << "Opened " << filename << "\n";
  }
  else {
    cerr << "Failed to open file " << filename << " " << strerror(errno) << "\n";
    return {false, banks_count, odins, 0, 0, 0, total_size};
  }

  bool success = true;
  size_t max_size = 0;

  size_t i_event = 0;

  std::array<unsigned, NBankTypes> bank_sizes;

  size_t alloc_size = 0, split_event = 0;

  bool is_mc = false, first = true;
  Allen::sd_from_raw_bank sd_from_raw;
  Allen::bank_sorter bank_sorter;

  while (true) {

    std::tie(eof, error, bank_span) = MDF::read_event(input, header, read_buffer, decompression_buffer, true, false);
    if (eof || error) {
      return {false, banks_count, odins, 0, 0, i_event, total_size};
    }
    else if (first) {
      first = false;
      std::tie(is_mc, sd_from_raw, bank_sorter) = file_type(bank_span);
    }

    bank_sizes.fill(0);

    // Put the banks in the event-local buffers
    char const* bank = bank_span.data();
    char const* end = bank_span.data() + bank_span.size();

    total_size += bank_span.size();

    while (bank < end) {
      const auto* b = reinterpret_cast<const LHCb::RawBank*>(bank);
      if (b->magic() != LHCb::RawBank::MagicPattern) {
        cout << "magic pattern failed: " << std::hex << b->magic() << std::dec << endl;
        success = false;
        goto error;
      }

      auto const allen_type = sd_from_raw(b);
      if (bank_types.count(allen_type)) {
        auto const at = to_integral(allen_type);
        auto const padded_size = b->totalSize() - b->hdrSize();
        bank_sizes[at] += padded_size;
        if (i_event == 0) {
          ++banks_count[at];
        }
      }

      if (allen_type == BankTypes::ODIN) {
        odins.emplace_back(MDF::decode_odin(b->version(), b->data()));
      }

      // Move to next raw bank
      bank += b->totalSize();
    }

    for (auto bank_type : bank_types) {
      auto const bt = to_integral(bank_type);
      // Count words in Allen layout so extra word for number of
      // banks, then n_banks + 1 for bank offsets, then each bank has
      // an extra word containing the source ID.
      auto extra_size = (2 + 2 * banks_count[bt]) * sizeof(uint32_t);
      sizes[bt].push_back(sizes[bt][i_event] + extra_size + bank_sizes[bt]);
      max_size = std::max(sizes[bt].back() + bank_span.size(), max_size);
    }

    if (i_event == min_events) {
      alloc_size = max_size + 1;
      for (auto bt : bank_types) {
        sizes[to_integral(bt)][i_event + 1] = 0;
      }
      max_size = 0;
      split_event = i_event;
    }
    else if (i_event > min_events && max_size > alloc_size) {
      odins.pop_back();
      break;
    }

    ++i_event;
  }

error:
  input.close();

  return {success, banks_count, odins, split_event, alloc_size, i_event, total_size};
}

int main(int argc, char* argv[])
{

  Catch::Session session; // There must be exactly one instance

  string mdf_file;

  // Build a new parser on top of Catch's
  using namespace Catch::clara;
  // Use Catch's composite command line parser
  auto cli = session.cli() | Opt(mdf_file, string {"file"})["--mdf-file"]("input file") |
             Opt(s_config.n_events, string {"#events"})["--nevents"]("number of events");

  // Now pass the new composite back to Catch so it uses that
  session.cli(cli);

  // Let Catch (using Clara) parse the command line
  int returnCode = session.applyCommandLine(argc, argv);
  if (returnCode != 0) {
    return returnCode;
  }

  s_config.run = !mdf_file.empty();

  if (!mdf_file.empty()) {
    if (mdf_file.find("root://") == 0) {
      s_config.mdf_files.push_back(mdf_file);
    }
    else {
      auto const p = fs::path(mdf_file);
      if (fs::is_regular_file(p) && p.extension() == ".mdf") {
        s_config.mdf_files.push_back(p.string());
      }
    }
  }

  return session.run();
}

TEST_CASE("MDF slice full", "[MDF slice]")
{
  if (!s_config.run) return;

  REQUIRE(!s_config.mdf_files.empty());

  auto filename = s_config.mdf_files[0];

  std::unordered_set<BankTypes> allen_types {
    BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN};

  auto [success, banks_count, odins, split_event, alloc_size, max_events, total_size] =
    mdf_read_sizes(filename, allen_types, s_config.n_events);
  REQUIRE(success == true);

  Allen::ReadBuffer read_buffer =
    std::tuple {0ul, std::vector<unsigned int>(max_events + 1), std::vector<char>(10 * total_size, '\0'), 0ul};

  std::vector<char> decompress_buffer;

  LHCb::MDFHeader header;
  EventIDs event_ids;
  vector<char> event_mask(max_events, 0);

  auto input = MDF::open(filename.c_str(), O_RDONLY);
  REQUIRE(input.good);

  // read the first header, needed by subsequent calls to read_events
  ssize_t n_bytes = input.read(reinterpret_cast<char*>(&header), mdf_header_size);
  REQUIRE(n_bytes == mdf_header_size);

  // read events
  auto [eof, error, bytes_read] = read_events(input, read_buffer, header, decompress_buffer, max_events, true);
  REQUIRE(!error);
  REQUIRE(max_events == std::get<0>(read_buffer));

  auto [is_mc, sd_from_raw, bank_sorter] = file_type({std::get<2>(read_buffer).data(), std::get<1>(read_buffer)[1]});

  input.close();

  std::cout << alloc_size << " " << split_event << " " << max_events << "\n";

  auto size_fun =
    [as = alloc_size, n_events = max_events, bc = banks_count](BankTypes) -> std::tuple<size_t, size_t, size_t> {
    auto n_banks = std::accumulate(bc.begin(), bc.end(), 0u);
    return {as, n_events * (n_banks + 1), n_events + 1};
  };

  auto slices = allocate_slices(s_config.n_slices, allen_types, size_fun);

  bool good = false, transpose_full = false;
  size_t n_transposed = 0;

  std::array<int, NBankTypes> banks_version {};

  for (auto [slice_index, check_full] : {std::tuple {0u, true}, std::tuple {1u, false}}) {
    std::tie(good, transpose_full, n_transposed) = transpose_events(
      read_buffer,
      slices,
      slice_index,
      allen_types,
      sd_from_raw,
      bank_sorter,
      banks_count,
      {},
      banks_version,
      event_ids,
      event_mask,
      max_events,
      false);
    std::cout << "transposed: " << n_transposed << " " << transpose_full << "\n";
    REQUIRE(good);
    REQUIRE(transpose_full == check_full);
    std::get<3>(read_buffer) += n_transposed;
  }
  REQUIRE(std::get<3>(read_buffer) == max_events);

  // Check that all events that were read have been transposed by
  // comparing event and run numbers from ODIN
  size_t i = 0;
  auto oi = to_integral(BankTypes::ODIN);
  for (auto const& slice : slices[oi]) {
    for (size_t j = 0; j < slice.n_offsets - 1; ++j) {
      auto const& read_odin = odins[i];
      auto const* odin_data =
        reinterpret_cast<unsigned const*>(slice.fragments[0].data() + slice.offsets[j] + 4 * sizeof(uint32_t));
      auto transposed_odin = MDF::decode_odin(banks_version[oi], odin_data);
      REQUIRE(read_odin.runNumber() == transposed_odin.runNumber());
      REQUIRE(read_odin.eventNumber() == transposed_odin.eventNumber());
      ++i;
    }
  }
}
