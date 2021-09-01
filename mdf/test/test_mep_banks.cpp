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

#include <Event/RawBank.h>
#include <read_mdf.hpp>
#include <read_mep.hpp>
#include <Timer.h>
#include <InputTools.h>
#include <MDFProvider.h>
#include <MEPProvider.h>
#include <TransposeMEP.h>
#include <ClusteringDefinitions.cuh>
#include <SciFiRaw.cuh>
#include <UTRaw.cuh>
#include <MuonRaw.cuh>

#define CATCH_CONFIG_RUNNER
#include <catch.hpp>

using namespace std;
using namespace std::string_literals;

struct Config {
  vector<string> mdf_files;
  vector<string> mep_files;
  size_t n_slices = 1;
  size_t n_events = 10;
  bool run = false;
};

namespace {
  Config s_config;
  MDFProviderConfig mdf_config {true, 2, 1};

  unique_ptr<MEPProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN>> mep;
  unique_ptr<MDFProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN>> mdf;

  size_t slice_mdf = 0, slice_mep = 0;
  size_t filled_mdf = 0, filled_mep = 0;

  vector<char> mep_buffer;
  Slices mep_slices;
  EventIDs events_mep;
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
    // Allocate providers and get slices
    mdf = make_unique<MDFProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN>>(
      s_config.n_slices, s_config.n_events, s_config.n_events, s_config.mdf_files, mdf_config);

    bool good = false, timed_out = false, done = false;
    uint runno = 0;
    std::tie(good, done, timed_out, slice_mdf, filled_mdf, runno) = mdf->get_slice();

    MEPProviderConfig mep_config {false, // verify MEP checksums
                                  2,     // number of read buffers
                                  1u,    // number of transpose threads
                                  4u,    // MPI sliding window size
                                  false, // Receive from MPI or read files
                                  false, // Run the application non-stop
                                  false, // MEPs should be transposed to Allen layout
                                  false, // Whether to split slices by run number
                                  {}};   // Map of receiver to MPI rank to receive from
    mep = std::make_unique<MEPProvider<BankTypes::VP, BankTypes::UT, BankTypes::FT, BankTypes::MUON, BankTypes::ODIN>>(
      s_config.n_slices, s_config.n_events, s_config.n_events, s_config.mep_files, mep_config);
    mep->start();
    std::tie(good, done, timed_out, slice_mep, filled_mep, runno) = mep->get_slice();
  }

  return session.run();
}

template<BankTypes BT>
void compare(
  const int,
  gsl::span<char const> mep_fragments,
  gsl::span<unsigned const> mep_offsets,
  gsl::span<char const> alle_fragments,
  gsl::span<unsigned const> allen_offsets,
  size_t const i_event);

template<typename... BankType>
void compare_UT(
  gsl::span<char const> mep_fragments,
  gsl::span<unsigned const> mep_offsets,
  gsl::span<char const> allen_fragments,
  gsl::span<unsigned const> allen_offsets,
  size_t const i_event);

template<>
void compare<BankTypes::VP>(
  const int,
  gsl::span<char const> mep_fragments,
  gsl::span<unsigned const> mep_offsets,
  gsl::span<char const> allen_banks,
  gsl::span<unsigned const> allen_offsets,
  size_t const i_event)
{
  auto const mep_n_banks = mep_offsets[0];

  const auto allen_raw_event = Velo::VeloRawEvent(allen_banks.data() + allen_offsets[i_event]);
  REQUIRE(mep_n_banks == allen_raw_event.number_of_raw_banks());

  for (unsigned bank = 0; bank < mep_n_banks; ++bank) {
    // Read raw bank
    auto const mep_bank = MEP::raw_bank<Velo::VeloRawBank>(mep_fragments.data(), mep_offsets.data(), i_event, bank);
    auto const allen_bank = allen_raw_event.raw_bank(bank);
    REQUIRE(mep_bank.sensor_index == allen_bank.sensor_index);
    REQUIRE(mep_bank.sp_count == allen_bank.sp_count);
    for (size_t j = 0; j < allen_bank.sp_count; ++j) {
      REQUIRE(allen_bank.sp_word[j] == mep_bank.sp_word[j]);
    }
  }
}

template<>
void compare<BankTypes::UT>(
  const int version,
  gsl::span<char const> mep_fragments,
  gsl::span<unsigned const> mep_offsets,
  gsl::span<char const> allen_banks,
  gsl::span<unsigned const> allen_offsets,
  size_t const i_event)
{
  auto const mep_n_banks = mep_offsets[0];

  const auto allen_raw_event = UTRawEvent(allen_banks.data() + allen_offsets[i_event]);
  REQUIRE(mep_n_banks == allen_raw_event.number_of_raw_banks);

  for (unsigned bank = 0; bank < mep_n_banks; ++bank) {
    // Read raw bank
    if (version == 3) {
      auto const mep_bank = MEP::raw_bank<UTRawBank<3>>(mep_fragments.data(), mep_offsets.data(), i_event, bank);
      auto const event_offset = allen_raw_event.raw_bank_offsets[bank];
      auto const allen_bank = allen_raw_event.getUTRawBank<3>(bank);
      REQUIRE(mep_bank.sourceID == allen_bank.sourceID);
      REQUIRE(mep_bank.number_of_hits == allen_bank.number_of_hits);
      for (size_t j = 0; j < ((allen_raw_event.raw_bank_offsets[bank + 1] - event_offset) >> 1) - 4; ++j) {
        REQUIRE(allen_bank.data[j] == mep_bank.data[j]);
      }
    }
    if (version == 4) {
      auto const mep_bank = MEP::raw_bank<UTRawBank<4>>(mep_fragments.data(), mep_offsets.data(), i_event, bank);
      auto const event_offset = allen_raw_event.raw_bank_offsets[bank];
      auto const allen_bank = allen_raw_event.getUTRawBank<4>(bank);
      REQUIRE(mep_bank.sourceID == allen_bank.sourceID);
      REQUIRE(mep_bank.number_of_hits == allen_bank.number_of_hits);
      for (size_t j = 0; j < ((allen_raw_event.raw_bank_offsets[bank + 1] - event_offset) >> 1) - 4; ++j) {
        REQUIRE(allen_bank.data[j] == mep_bank.data[j]);
      }
    }
  }
}

template<>
void compare<BankTypes::FT>(
  const int,
  gsl::span<char const> mep_fragments,
  gsl::span<unsigned const> mep_offsets,
  gsl::span<char const> allen_banks,
  gsl::span<unsigned const> allen_offsets,
  size_t const i_event)
{
  auto const mep_n_banks = mep_offsets[0];

  const auto allen_raw_event = SciFi::SciFiRawEvent(allen_banks.data() + allen_offsets[i_event]);
  REQUIRE(mep_n_banks == allen_raw_event.number_of_raw_banks());

  for (unsigned bank = 0; bank < mep_n_banks; ++bank) {
    // Read raw bank
    auto const mep_bank = MEP::raw_bank<SciFi::SciFiRawBank>(mep_fragments.data(), mep_offsets.data(), i_event, bank);
    auto const allen_bank = allen_raw_event.raw_bank(bank);
    auto mep_len = mep_bank.last - mep_bank.data;
    auto allen_len = allen_bank.last - allen_bank.data;
    REQUIRE(mep_bank.sourceID == allen_bank.sourceID);
    REQUIRE(mep_len == allen_len);
    for (long j = 0; j < mep_len; ++j) {
      REQUIRE(allen_bank.data[j] == mep_bank.data[j]);
    }
  }
}

template<>
void compare<BankTypes::MUON>(
  const int,
  gsl::span<char const> mep_fragments,
  gsl::span<unsigned const> mep_offsets,
  gsl::span<char const> allen_banks,
  gsl::span<unsigned const> allen_offsets,
  size_t const i_event)
{
  auto const mep_n_banks = mep_offsets[0];

  const auto allen_raw_event = Muon::MuonRawEvent(allen_banks.data() + allen_offsets[i_event]);
  REQUIRE(mep_n_banks == allen_raw_event.number_of_raw_banks());

  for (unsigned bank = 0; bank < mep_n_banks; ++bank) {
    // Read raw bank
    auto const mep_bank = MEP::raw_bank<Muon::MuonRawBank>(mep_fragments.data(), mep_offsets.data(), i_event, bank);
    auto const allen_bank = allen_raw_event.raw_bank(bank);
    auto mep_len = mep_bank.last - mep_bank.data;
    auto allen_len = allen_bank.last - allen_bank.data;
    REQUIRE(mep_bank.sourceID == allen_bank.sourceID);
    REQUIRE(mep_len == allen_len);
    for (long j = 0; j < mep_len; ++j) {
      REQUIRE(allen_bank.data[j] == mep_bank.data[j]);
    }
  }
}

template<BankTypes BT_>
struct BTTag {
  inline static const BankTypes BT = BT_;
};

using VeloTag = BTTag<BankTypes::VP>;
using SciFiTag = BTTag<BankTypes::FT>;
using UTTag = BTTag<BankTypes::UT>;
using MuonTag = BTTag<BankTypes::MUON>;

/**
 * @brief      Check banks
 */
template<BankTypes BT>
void check_banks(BanksAndOffsets const& mep_data, BanksAndOffsets const& allen_data, size_t const n_events)
{
  // In MEP layout the fragmets are split into MFPs that are not
  // contiguous in memory. When the data is copied to the device the
  // MFPs are copied into device memory back-to-back, making them
  // contiguous; the offsets are prepared with this in mind.

  // To make direct use of the offsets, the MFPs need to be copied
  // into temporary storage
  auto const& mfps = std::get<0>(mep_data);
  auto const& mep_offsets = std::get<2>(mep_data);
  vector<char> mep_fragments(std::get<1>(mep_data), 0);
  char* destination = &mep_fragments[0];
  for (gsl::span<char const> mfp : mfps) {
    ::memcpy(destination, mfp.data(), mfp.size_bytes());
    destination += mfp.size_bytes();
  }

  // Allen banks; the fragments are already contiguous
  auto const& allen_banks = std::get<0>(allen_data);
  auto const& allen_offsets = std::get<2>(allen_data);

  // In Allen layout the first uint32_t for each event is the number
  // of banks, while in MEP layout the first uint32_t in the offsets
  // is the number of banks. Compare them to make sure things are
  // consistent
  for (size_t i = 0; i < n_events; ++i) {
    REQUIRE(reinterpret_cast<uint32_t const*>(allen_banks[0].data() + allen_offsets[i])[0] == mep_offsets[0]);
    compare<BT>(std::get<3>(mep_data), mep_fragments, mep_offsets, allen_banks[0], allen_offsets, i);
  }
}

// Main test case, multiple bank types are checked
TEMPLATE_TEST_CASE("MEP vs MDF", "[MEP MDF]", VeloTag, UTTag, SciFiTag, MuonTag)
{
  if (!s_config.run) return;

  // Check that the number of events read matches
  REQUIRE(filled_mep == filled_mdf);

  auto mep_banks = mep->banks(TestType::BT, slice_mep);
  auto mdf_banks = mdf->banks(TestType::BT, slice_mdf);

  // Compare reported versions
  REQUIRE(std::get<3>(mep_banks) == std::get<3>(mdf_banks));

  SECTION("Checking banks") { check_banks<TestType::BT>(mep_banks, mdf_banks, s_config.n_events); }
}
