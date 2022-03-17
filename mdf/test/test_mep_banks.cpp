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

#include <nlohmann/json.hpp>

#include <TransposeTypes.h>
#include <Provider.h>
#include <ProgramOptions.h>
#include <MEPTools.h>
#include <Event/RawBank.h>
#include <Timer.h>
#include <ClusteringDefinitions.cuh>
#include <SciFiRaw.cuh>
#include <UTRaw.cuh>
#include <MuonRaw.cuh>
#include <CaloRawEvent.cuh>
#include <ODINBank.cuh>

#include <GaudiKernel/Bootstrap.h>
#include <GaudiKernel/IProperty.h>
#include <GaudiKernel/IAppMgrUI.h>
#include <GaudiKernel/IStateful.h>
#include <GaudiKernel/ISvcLocator.h>
#include <GaudiKernel/SmartIF.h>

#ifdef USE_BOOST_FILESYSTEM
#include <boost/filesystem.hpp>
#else
#include <filesystem>
#endif

#define CATCH_CONFIG_RUNNER
#include <catch2/catch.hpp>

using namespace std;
using namespace std::string_literals;

struct Config {
  std::string mdf_files;
  std::string mep_files;
  size_t n_slices = 1;
  size_t n_events = 10;
  size_t eps = 0;
  bool run = false;
  std::string sequence;
  bool transpose_mep = false;

  std::unordered_map<EventID, unsigned> mdf_slices;
  std::unordered_map<EventID, unsigned> mep_slices;
};

namespace {
  Config s_config;

  std::shared_ptr<IInputProvider> mdf;
  IInputProvider* mep;

#ifdef USE_BOOST_FILESYSTEM
  namespace fs = boost::filesystem;
#else
  namespace fs = std::filesystem;
#endif

  using json = nlohmann::json;
} // namespace

fs::path write_json(std::unordered_set<BankTypes> const& bank_types)
{

  // Write a JSON file that can be fed to AllenConfiguration to
  // determine the bank types.
  json bank_types_json;
  for (auto bt : bank_types) {
    bank_types_json["provide_"s + bank_name(bt)]["bank_type"] = bank_name(bt);
  }

  auto bt_filename = fs::canonical(fs::current_path()) / "bank_types.json";
  std::ofstream bt_json(bt_filename.string());
  if (!bt_json.is_open()) {
    std::cerr << "Failed to open json file for bank types configuration"
              << "\n";
    return {};
  }
  else {
    bt_json << std::setw(4) << bank_types_json.dump() << "\n";
    return bt_filename;
  }
}

IInputProvider* mep_provider(std::string json_file)
{

  SmartIF<IStateful> app = Gaudi::createApplicationMgr();
  auto prop = app.as<IProperty>();
  bool sc = prop->setProperty("ExtSvc", "[\"AllenConfiguration\", \"MEPProvider\"]").isSuccess();
  sc &= prop->setProperty("JobOptionsType", "\"NONE\"");
  sc &= app->configure();

  auto sloc = app.as<ISvcLocator>();

  auto allen_conf = sloc->service<IService>("AllenConfiguration");
  if (!allen_conf) return nullptr;
  auto allen_conf_prop = allen_conf.as<IProperty>();
  sc &= allen_conf_prop->setProperty("JSON", json_file).isSuccess();

  if (!sc) return nullptr;

  auto provider = sloc->service<IService>("MEPProvider");
  if (!provider) return nullptr;
  auto provider_prop = provider.as<IProperty>();
  sc &= provider_prop->setProperty("NSlices", std::to_string(s_config.n_slices)).isSuccess();
  sc &= provider_prop->setProperty("EventsPerSlice", std::to_string(s_config.eps));
  sc &= provider_prop->setProperty("EvtMax", std::to_string(s_config.n_events));
  sc &= provider_prop->setProperty("SplitByRun", "0");
  sc &= provider_prop->setProperty("Source", "\"Files\"");
  sc &= provider_prop->setProperty("BufferConfig", "(1, 1)");
  sc &= provider_prop->setProperty("OutputLevel", "2");

  auto mep_files = split_string(s_config.mep_files, ",");
  std::stringstream ss;
  ss << "[\"" << mep_files.front();
  mep_files.erase(mep_files.begin());
  for (auto f : mep_files) {
    ss << "\",\"" << f;
  }
  ss << "\"]";
  sc &= provider_prop->setProperty("Connections", ss.str());

  sc &= app->initialize();
  sc &= app->start();
  return dynamic_cast<IInputProvider*>(provider.get());
}

int main(int argc, char* argv[])
{

  Catch::Session session; // There must be exactly one instance

  // Build a new parser on top of Catch's
  using namespace Catch::clara;
  auto cli = session.cli()                                   // Get Catch's composite command line parser
             | Opt(s_config.mdf_files, string {"MDF files"}) // bind variable to a new option, with a hint string
                 ["--mdf"]("MDF files") |
             Opt(s_config.mep_files, string {"MEP files"}) // bind variable to a new option, with a hint string
               ["--mep"]("MEP files") |
             Opt(s_config.n_events, string {"#events"}) // bind variable to a new option, with a hint string
               ["--nevents"]("number of events") |
             Opt(s_config.eps, string {"#events-per-slice"}) // bind variable to a new option, with a hint string
               ["--eps"]("number of events per slice");

  // Now pass the new composite back to Catch so it uses that
  session.cli(cli);

  // Let Catch (using Clara) parse the command line
  int returnCode = session.applyCommandLine(argc, argv);
  if (returnCode != 0) {
    return returnCode;
  }
  std::cout << "mdf_files = " << s_config.mdf_files << std::endl;
  std::cout << "mep_files = " << s_config.mep_files << std::endl;
  s_config.run = !s_config.mdf_files.empty();

  if (s_config.eps == 0) s_config.eps = s_config.n_events;
  s_config.n_slices = (s_config.n_events - 1) / s_config.eps + 1;

  logger::setVerbosity(4);

  if (s_config.run) {
    // std::unordered_set<BankTypes> bank_types = {BankTypes::VP,
    //                                             BankTypes::UT,
    //                                             BankTypes::FT,
    //                                             BankTypes::ODIN,
    //                                             BankTypes::ECal,
    //                                             BankTypes::HCal,
    //                                             BankTypes::MUON};
    std::unordered_set<BankTypes> bank_types = {
      BankTypes::ODIN, BankTypes::ECal, BankTypes::Rich2, BankTypes::MUON};
    auto json_file = write_json(bank_types);

    // Allocate providers and get slices
    std::map<std::string, std::string> options = {{"s", std::to_string(s_config.n_slices)},
                                                  {"n", std::to_string(s_config.n_events)},
                                                  {"mdf", s_config.mdf_files},
                                                  {"sequence", json_file.string()},
                                                  {"run-from-json", "1"},
                                                  {"events-per-slice", std::to_string(s_config.eps)},
                                                  {"disable-run-changes", "1"}};

    mdf = Allen::make_provider(options);
    if (!mdf) {
      std::cerr << "Failed to obtain MDFProvider\n";
      return 1;
    }

    mep = mep_provider(json_file.string());
    if (mep == nullptr) {
      std::cerr << "Failed to obtain MEPProvider\n";
      return 1;
    }

    bool good = false, timed_out = false, done = false;
    unsigned slice_id = 0, n_filled = 0;
    uint runno = 0;

    for (size_t s = 0; s < s_config.n_slices; ++s) {
      std::any odin;
      std::tie(good, done, timed_out, slice_id, n_filled, odin) = mdf->get_slice();
      if (!good) {
        std::cerr << "Failed to obtain MDF slice " << s << "\n";
        return 1;
      }

      auto events_mdf = mdf->event_ids(slice_id);
      auto first_id = events_mdf.front();
      s_config.mdf_slices.emplace(std::move(first_id), slice_id);

      std::tie(good, done, timed_out, slice_id, n_filled, odin) = mep->get_slice();
      if (!good) {
        std::cerr << "Failed to obtain MEP slice " << s << "\n";
        return 1;
      }

      auto events_mep = mep->event_ids(slice_id);
      first_id = events_mep.front();
      s_config.mep_slices.emplace(std::move(first_id), slice_id);
    }

  }

  auto r = session.run();

  for (auto [id, slice_mdf] : s_config.mdf_slices) {
    mdf->slice_free(slice_mdf);
  }

  for (auto [id, slice_mep] : s_config.mep_slices) {
    mep->slice_free(slice_mep);
  }

  return r;
}

template<BankTypes BT, bool transpose_mep>
struct compare {};

template<bool transpose_mep>
struct compare<BankTypes::ODIN, transpose_mep> {
  void operator()(
    const int,
    gsl::span<char const> mep_fragments,
    gsl::span<unsigned const> mep_offsets,
    gsl::span<unsigned const> mep_sizes,
    gsl::span<char const> allen_banks,
    gsl::span<unsigned const> allen_offsets,
    gsl::span<unsigned const> allen_sizes,
    size_t const i_event)
  {
    const auto allen_bank = odin_bank<false>(allen_banks.data(), allen_offsets.data(), allen_sizes.data(), i_event);
    const auto mep_bank = odin_bank<!transpose_mep>(mep_fragments.data(), mep_offsets.data(), mep_sizes.data(), i_event);

    REQUIRE(allen_bank.size == mep_bank.size);
    for (unsigned short i = 0; i < allen_bank.size; ++i) {
      REQUIRE(allen_bank.data[i] == mep_bank.data[i]);
    }
  }
};

template<bool transpose_mep>
struct compare<BankTypes::VP, transpose_mep> {
  void operator()(
    const int,
    gsl::span<char const> mep_fragments,
    gsl::span<unsigned const> mep_offsets,
    gsl::span<unsigned const> mep_sizes,
    gsl::span<char const> allen_banks,
    gsl::span<unsigned const> allen_offsets,
    gsl::span<unsigned const> allen_sizes,
    size_t const i_event)
  {
    const auto allen_raw_event = Velo::RawEvent<false>(allen_banks.data(), allen_offsets.data(), allen_sizes.data(), i_event);
    const auto mep_raw_event = Velo::RawEvent<!transpose_mep>(mep_fragments.data(), mep_offsets.data(), mep_sizes.data(), i_event);
    auto const mep_n_banks = mep_raw_event.number_of_raw_banks();

    REQUIRE(mep_n_banks == allen_raw_event.number_of_raw_banks());

    for (unsigned bank = 0; bank < mep_n_banks; ++bank) {
      // Read raw bank
      auto const mep_bank = mep_raw_event.raw_bank(bank);
      auto const allen_bank = allen_raw_event.raw_bank(bank);
      auto top5_mask = (allen_bank.sensor_index >> 11 == 0) ? 0x7FF : 0xFFFF;
      REQUIRE((mep_bank.sensor_index & top5_mask) == allen_bank.sensor_index);
      REQUIRE(mep_bank.count == allen_bank.count);
      for (size_t j = 0; j < allen_bank.count; ++j) {
        REQUIRE(allen_bank.word[j] == mep_bank.word[j]);
      }
    }
  }
};

template<bool transpose_mep>
struct compare<BankTypes::UT, transpose_mep> {
  void operator()(
    const int version,
    gsl::span<char const> mep_fragments,
    gsl::span<unsigned const> mep_offsets,
    gsl::span<unsigned const> mep_sizes,
    gsl::span<char const> allen_banks,
    gsl::span<unsigned const> allen_offsets,
    gsl::span<unsigned const> allen_sizes,
    size_t const i_event)
  {
    const auto allen_raw_event = UTRawEvent<false>{allen_banks.data(), allen_offsets.data(), allen_sizes.data(), i_event};
    const auto mep_raw_event = UTRawEvent<!transpose_mep>{mep_fragments.data(), mep_offsets.data(), mep_sizes.data(), i_event};
    auto const mep_n_banks = mep_raw_event.number_of_raw_banks();

    REQUIRE(mep_n_banks == allen_raw_event.number_of_raw_banks());

    for (unsigned bank = 0; bank < mep_n_banks; ++bank) {
      // Read raw bank
      if (version == 3) {
        auto const mep_bank = mep_raw_event.raw_bank<3>(bank);;
        auto const allen_bank = allen_raw_event.raw_bank<3>(bank);
        auto top5_mask = (allen_bank.sourceID >> 11 == 0) ? 0x7FF : 0xFFFF;
        REQUIRE((mep_bank.sourceID & top5_mask) == allen_bank.sourceID);
        REQUIRE(mep_bank.number_of_hits == allen_bank.number_of_hits);

        for (size_t j = 0; j < allen_bank.size; ++j) {
          REQUIRE(allen_bank.data[j] == mep_bank.data[j]);
        }
      }
      if (version == 4) {
        auto const mep_bank = mep_raw_event.raw_bank<4>(bank);
        auto const allen_bank = allen_raw_event.raw_bank<4>(bank);

        // skip buggy banks without content
        if (allen_bank.size < sizeof(uint32_t) * 6) continue;

        auto top5_mask = (allen_bank.sourceID >> 11 == 0) ? 0x7FF : 0xFFFF;
        REQUIRE((mep_bank.sourceID & top5_mask) == allen_bank.sourceID);
        REQUIRE(mep_bank.number_of_hits == allen_bank.number_of_hits);

        for (size_t j = 0; j < allen_bank.size; ++j) {
          REQUIRE(allen_bank.data[j] == mep_bank.data[j]);
        }
      }
    }
  }
};

template<bool transpose_mep>
struct compare<BankTypes::FT, transpose_mep> {
  void operator()(
    const int,
    gsl::span<char const> mep_fragments,
    gsl::span<unsigned const> mep_offsets,
    gsl::span<unsigned const> mep_sizes,
    gsl::span<char const> allen_banks,
    gsl::span<unsigned const> allen_offsets,
    gsl::span<unsigned const> allen_sizes,
    size_t const i_event)
  {
    const auto allen_raw_event = SciFi::RawEvent<false>(allen_banks.data(), allen_offsets.data(), allen_sizes.data(), i_event);
    const auto mep_raw_event = SciFi::RawEvent<!transpose_mep>(mep_fragments.data(), mep_offsets.data(), mep_sizes.data(), i_event);
    auto const mep_n_banks = mep_raw_event.number_of_raw_banks();

    REQUIRE(mep_n_banks == allen_raw_event.number_of_raw_banks());

    for (unsigned bank = 0; bank < mep_n_banks; ++bank) {
      // Read raw bank
      auto const mep_bank = mep_raw_event.raw_bank(bank);
      auto const allen_bank = allen_raw_event.raw_bank(bank);
      auto mep_len = mep_bank.last - mep_bank.data;
      auto allen_len = allen_bank.last - allen_bank.data;
      auto top5_mask = (allen_bank.sourceID >> 11 == 0) ? 0x7FF : 0xFFFF;
      REQUIRE((mep_bank.sourceID & top5_mask) == allen_bank.sourceID);
      REQUIRE(mep_len == allen_len);
      for (long j = 0; j < mep_len; ++j) {
        REQUIRE(allen_bank.data[j] == mep_bank.data[j]);
      }
    }
  }
};

template<bool transpose_mep>
struct compare<BankTypes::MUON, transpose_mep> {
  void operator()(const int,
    gsl::span<char const> mep_fragments,
    gsl::span<unsigned const> mep_offsets,
    gsl::span<unsigned const> mep_sizes,
    gsl::span<char const> allen_banks,
    gsl::span<unsigned const> allen_offsets,
    gsl::span<unsigned const> allen_sizes,
    size_t const i_event)
  {

    const auto allen_raw_event = Muon::RawEvent<false, 3>(allen_banks.data(), allen_offsets.data(), allen_sizes.data(), i_event);
    const auto mep_raw_event = Muon::RawEvent<!transpose_mep, 3>(mep_fragments.data(), mep_offsets.data(), mep_sizes.data(), i_event);
    auto const mep_n_banks = mep_raw_event.number_of_raw_banks();

    REQUIRE(mep_n_banks == allen_raw_event.number_of_raw_banks());

    for (unsigned bank = 0; bank < mep_n_banks; ++bank) {
      // Read raw bank
      auto const mep_bank = mep_raw_event.raw_bank(bank);
      auto const allen_bank = allen_raw_event.raw_bank(bank);
      auto mep_len = mep_bank.last - mep_bank.data;
      auto allen_len = allen_bank.last - allen_bank.data;
      auto top5_mask = (allen_bank.sourceID >> 11 == 0) ? 0x7FF : 0xFFFF;
      REQUIRE((mep_bank.sourceID & top5_mask) == allen_bank.sourceID);
      REQUIRE(mep_len == allen_len);
      for (long j = 0; j < mep_len; ++j) {
        REQUIRE(allen_bank.data[j] == mep_bank.data[j]);
      }
    }
  }
};

template<bool transpose_mep>
struct compare<BankTypes::ECal, transpose_mep> {
  void operator()(
    const int,
    gsl::span<char const> mep_fragments,
    gsl::span<unsigned const> mep_offsets,
    gsl::span<unsigned const> mep_sizes,
    gsl::span<char const> allen_banks,
    gsl::span<unsigned const> allen_offsets,
    gsl::span<unsigned const> allen_sizes,
    size_t const i_event)
  {

    const auto allen_raw_event = Calo::RawEvent<false>(allen_banks.data(), allen_offsets.data(), allen_sizes.data(), i_event);
    const auto mep_raw_event = Calo::RawEvent<!transpose_mep>(mep_fragments.data(), mep_offsets.data(), mep_sizes.data(), i_event);
    auto const mep_n_banks = mep_raw_event.number_of_raw_banks;

    REQUIRE(mep_n_banks == allen_raw_event.number_of_raw_banks);

    for (unsigned bank = 0; bank < mep_n_banks; ++bank) {
      // Read raw bank
      auto const mep_bank = mep_raw_event.raw_bank(bank);
      auto const allen_bank = allen_raw_event.raw_bank(bank);
      auto mep_len = mep_bank.end - mep_bank.data;
      auto allen_len = allen_bank.end - allen_bank.data;
      auto top5_mask = (allen_bank.source_id >> 11 == 0) ? 0x7FF : 0xFFFF;
      REQUIRE((mep_bank.source_id & top5_mask) == allen_bank.source_id);
      REQUIRE(mep_len == allen_len);
      for (long j = 0; j < mep_len; ++j) {
        REQUIRE(allen_bank.data[j] == mep_bank.data[j]);
      }
    }
  }
};

template<BankTypes BT_>
struct BTTag {
  inline static const BankTypes BT = BT_;
};

using ODINTag = BTTag<BankTypes::ODIN>;
using VeloTag = BTTag<BankTypes::VP>;
using SciFiTag = BTTag<BankTypes::FT>;
using UTTag = BTTag<BankTypes::UT>;
using MuonTag = BTTag<BankTypes::MUON>;
using ECalTag = BTTag<BankTypes::ECal>;

/**
 * @brief      Check banks
 */
template<BankTypes BT, bool transpose_mep>
void check_banks(BanksAndOffsets const& mep_data, BanksAndOffsets const& allen_data, size_t const n_events)
{
  // In MEP layout the fragmets are split into MFPs that are not
  // contiguous in memory. When the data is copied to the device the
  // MFPs are copied into device memory back-to-back, making them
  // contiguous; the offsets are prepared with this in mind.

  // To make direct use of the offsets, the MFPs need to be copied
  // into temporary storage
  auto const& mfps = mep_data.fragments;
  auto const& mep_offsets = mep_data.offsets;
  auto const& mep_sizes = mep_data.sizes;
  vector<char> mep_fragments(mep_data.fragments_mem_size, 0);

  char* destination = &mep_fragments[0];
  if constexpr (transpose_mep) {
    ::memcpy(destination, mfps[0].data(), mep_data.fragments_mem_size);
  } else {
    for (auto mfp : mfps) {
      ::memcpy(destination, mfp.data(), mfp.size_bytes());
      destination += mfp.size_bytes();
    }
    assert(static_cast<size_t>(destination - mep_fragments.data()) == mep_data.fragments_mem_size);
  }

  // Allen banks; the fragments are already contiguous
  auto const& allen_banks = allen_data.fragments;
  auto const& allen_offsets = allen_data.offsets;
  auto const& allen_sizes = allen_data.sizes;

  // In Allen layout the first uint32_t for each event is the number
  // of banks, while in MEP layout the first uint32_t in the offsets
  // is the number of banks. Compare them to make sure things are
  // consistent
  for (size_t i = 0; i < n_events; ++i) {
    REQUIRE(reinterpret_cast<uint32_t const*>(allen_banks[0].data() + allen_offsets[i])[0] == mep_offsets[0]);
    compare<BT, transpose_mep>{}(mep_data.version, mep_fragments, mep_offsets, mep_sizes, allen_banks[0], allen_offsets, allen_sizes, i);
  }
}

// Main test case, multiple bank types are checked
// VeloTag, UTTag, SciFiTag,
TEMPLATE_TEST_CASE("MEP vs MDF", "[MEP MDF]", ODINTag, ECalTag, MuonTag)
{
  if (!s_config.run) return;

  for (auto [event_id, slice_mdf] : s_config.mdf_slices) {

    auto it = s_config.mep_slices.find(event_id);
    REQUIRE(it != s_config.mep_slices.end());

    auto const slice_mep = it->second;

    auto events_mdf = mdf->event_ids(slice_mdf);
    auto events_mep = mep->event_ids(slice_mep);

    for (size_t i = 0; i < events_mdf.size(); ++i) {
      auto [run_mdf, event_mdf] = events_mdf[i];
      auto [run_mep, event_mep] = events_mep[i];
      REQUIRE(run_mdf == run_mep);
      REQUIRE(event_mdf == event_mep);
    }

    auto mdf_banks = mdf->banks(TestType::BT, slice_mdf);
    auto mep_banks = mep->banks(TestType::BT, slice_mep);

    // Compare reported versions
    REQUIRE(mep_banks.version == mdf_banks.version);

    SECTION(std::string{"Checking "} + bank_name(TestType::BT) + " banks") {
      if (s_config.transpose_mep) {
        check_banks<TestType::BT, true>(mep_banks, mdf_banks, s_config.eps);
      }
      else {
        check_banks<TestType::BT, false>(mep_banks, mdf_banks, s_config.eps);
      }
    }
  }
}
