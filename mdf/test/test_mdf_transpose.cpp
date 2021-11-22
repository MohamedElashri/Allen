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

#define CATCH_CONFIG_RUNNER
#include <catch.hpp>

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

std::tuple<
  bool,
  std::array<unsigned, LHCb::RawBank::types().size()>,
  std::vector<LHCb::ODIN>,
  size_t,
  size_t,
  size_t,
  size_t>
mdf_read_sizes(
  std::string filename,
  std::vector<int> const& bank_ids,
  std::unordered_set<LHCb::RawBank::BankType> const& bank_types,
  size_t min_events)
{
  // Storage for the sizes
  std::array<std::vector<size_t>, LHCb::RawBank::types().size()> sizes;
  for (auto bt : bank_types) {
    sizes[bt].push_back(0);
  }

  std::array<unsigned, LHCb::RawBank::types().size()> banks_count;
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

  std::array<unsigned, LHCb::RawBank::types().size()> bank_sizes;

  size_t alloc_size = 0, split_event = 0;

  while (true) {

    std::tie(eof, error, bank_span) = MDF::read_event(input, header, read_buffer, decompression_buffer, true, true);
    if (eof || error) {
      return {false, banks_count, odins, 0, 0, i_event, total_size};
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

      if (b->type() < LHCb::RawBank::LastType && bank_types.count(b->type())) {
        bank_sizes[b->type()] += b->size();
        if (i_event == 0) {
          ++banks_count[b->type()];
        }
      }

      if (b->type() == LHCb::RawBank::ODIN) {
        odins.emplace_back(MDF::decode_odin(b->version(), b->data()));
      }

      // Move to next raw bank
      bank += b->totalSize();
    }

    for (auto bt : bank_types) {
      auto lhcb_type = bank_ids[to_integral(bt)];
      // Count words in Allen layout so extra word for number of
      // banks, then n_banks + 1 for bank offsets, then each bank has
      // an extra word containing the source ID.
      auto offsets_size = (2 + 2 * banks_count[lhcb_type]) * sizeof(uint32_t);
      sizes[bt].push_back(sizes[bt][i_event] + offsets_size + bank_sizes[bt]);
      max_size = std::max(sizes[bt].back() + bank_span.size(), max_size);
    }

    if (i_event == min_events) {
      alloc_size = max_size + 1;
      for (auto bt : bank_types) {
        sizes[bt][i_event + 1] = 0;
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

  string directory;

  // Build a new parser on top of Catch's
  using namespace Catch::clara;
  // Use Catch's composite command line parser
  auto cli = session.cli() | Opt(directory, string {"directory"})["--directory"]("input directory") |
             Opt(s_config.n_events, string {"#events"})["--nevents"]("number of events");

  // Now pass the new composite back to Catch so it uses that
  session.cli(cli);

  // Let Catch (using Clara) parse the command line
  int returnCode = session.applyCommandLine(argc, argv);
  if (returnCode != 0) {
    return returnCode;
  }

  s_config.run = !directory.empty();

  for (auto file : s_config.mdf_files) {
    std::cout << " File name = " << file << std::endl;
  }

  if (!directory.empty()) {
    for (auto& file : s_config.mdf_files) {
      const auto filename = directory + "/mdf/" + file;
      if (std::filesystem::exists(filename)) {
        file = filename;
      }
      else {
        return 1;
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

  auto ids = Allen::bank_ids();
  std::unordered_map<BankTypes, unsigned> allen_to_lhcb;
  for (unsigned lhcb_type = 0; lhcb_type < ids.size(); ++lhcb_type) {
    auto allen_type = ids[lhcb_type];
    if (allen_type != -1) {
      allen_to_lhcb.emplace(BankTypes {allen_type}, lhcb_type);
    }
  }

  std::unordered_set<LHCb::RawBank::BankType> bank_types;
  for (auto bt : {BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN}) {
    auto it = allen_to_lhcb.find(bt);
    REQUIRE(it != allen_to_lhcb.end());
    bank_types.insert(static_cast<LHCb::RawBank::BankType>(it->second));
  }

  auto [success, banks_count, odins, split_event, alloc_size, max_events, total_size] =
    mdf_read_sizes(filename, ids, bank_types, s_config.n_events);
  REQUIRE(success == true);

  Allen::ReadBuffer read_buffer =
    std::tuple {0ul, std::vector<unsigned int>(max_events + 1), std::vector<char>(10 * total_size, '\0'), 0ul};

  std::vector<char> decompress_buffer;

  LHCb::MDFHeader header;
  std::vector<EventIDs> event_ids(s_config.n_slices);

  auto input = MDF::open(filename.c_str(), O_RDONLY);
  REQUIRE(input.good);

  // read the first header, needed by subsequent calls to read_events
  ssize_t n_bytes = input.read(reinterpret_cast<char*>(&header), mdf_header_size);
  REQUIRE(n_bytes == mdf_header_size);

  // read events
  auto [eof, error, buffer_full, bytes_read] =
    read_events(input, read_buffer, header, decompress_buffer, max_events, true);
  REQUIRE(!error);
  REQUIRE(!buffer_full);
  REQUIRE(max_events == std::get<0>(read_buffer));

  input.close();

  std::cout << alloc_size << " " << split_event << " " << max_events << "\n";

  auto size_fun = [as = alloc_size, n_events = max_events](BankTypes) -> std::tuple<size_t, size_t> {
    return {as, n_events + 1};
  };

  std::unordered_set<BankTypes> allen_types {
    BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN};
  auto slices = allocate_slices(s_config.n_slices, allen_types, size_fun);

  bool good = false, transpose_full = false;
  size_t n_transposed = 0;

  std::array<int, NBankTypes> banks_version {};

  for (auto [slice_index, check_full] : {std::tuple {0u, true}, std::tuple {1u, false}}) {
    std::tie(good, transpose_full, n_transposed) = transpose_events(
      read_buffer, slices, slice_index, ids, allen_types, banks_count, banks_version, event_ids[0], max_events, false);
    std::cout << "transposed: " << n_transposed << " " << transpose_full << "\n";
    REQUIRE(good);
    REQUIRE(transpose_full == check_full);
    std::get<3>(read_buffer) += n_transposed;
  }
  REQUIRE(std::get<3>(read_buffer) == max_events);

  // Check that all events that were read have been transposed by
  // comparing event and run numbers from ODIN
  size_t i = 0;
  for (auto const& [banks, _, event_offsets, n_offsets] : slices[to_integral(BankTypes::ODIN)]) {
    for (size_t j = 0; j < n_offsets - 1; ++j) {
      auto const& read_odin = odins[i];
      auto const* odin_data =
        reinterpret_cast<unsigned const*>(banks[0].data() + event_offsets[j] + 4 * sizeof(uint32_t));
      auto transposed_odin = MDF::decode_odin(0, odin_data);
      REQUIRE(read_odin.runNumber() == transposed_odin.runNumber());
      REQUIRE(read_odin.eventNumber() == transposed_odin.eventNumber());
      ++i;
    }
  }
}
