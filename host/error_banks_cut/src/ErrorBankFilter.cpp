/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include <string>
#include <vector>
#include <map>
#include <nlohmann/json.hpp>
#include <nlohmann/ordered_map.hpp>
#include <boost/dynamic_bitset.hpp>

#include "ErrorBankFilter.h"
#include <sourceid.h>
#include <Event/RawBank.h>

INSTANTIATE_ALGORITHM(error_bank_filter::error_bank_filter_t)

void error_bank_filter::from_json(const nlohmann::json& j, error_bank_filter::bank_types_t& sdb)
{
  std::string dt {"data_types"}, ot {"other_types"}, et {"error_types"};
  for (auto& [k, v] : {std::tie(dt, sdb.data_types), std::tie(ot, sdb.other_types), std::tie(et, sdb.error_types)}) {
    if (j.contains(k)) {
      v = j.at(k).get<std::vector<std::string>>();
    }
    else {
      v = std::vector<std::string> {};
    }
  }
}

void error_bank_filter::to_json(nlohmann::json& j, error_bank_filter::bank_types_t const& sdb)
{
  j.at("data_types") = sdb.data_types;
  j.at("other_types") = sdb.other_types;
  j.at("error_types") = sdb.error_types;
}

void error_bank_filter::error_bank_filter_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  auto const n_events = size<host_event_list_t>(arguments);

  set_size<host_number_of_selected_events_t>(arguments, 1);
  set_size<dev_output_event_list_t>(arguments, n_events);
  set_size<host_output_event_list_t>(arguments, n_events);
  set_size<host_temp_counts_t>(arguments, 5 * LHCb::RawBank::LastType);
}

void error_bank_filter::error_bank_filter_t::init()
{
#ifndef ALLEN_STANDALONE
  std::map<std::string, bank_types_t> sd_bank_types = property<sd_bank_types_t>();
  std::vector<std::string> daq_error_types = property<daq_error_types_t>();

  std::vector<std::string> source_names, data_names, other_names, error_names = daq_error_types;

  auto names_to_types = [](std::vector<std::string> const& names) {
    std::vector<LHCb::RawBank::BankType> types;
    if (Gaudi::Parsers::parse(types, Gaudi::Utils::toString(names)).isFailure()) {
      throw StrException("Unknown bank type encountered: " + Gaudi::Utils::toString(names));
    }
    std::sort(types.begin(), types.end());
    types.erase(std::unique(types.begin(), types.end()), types.end());
    return types;
  };

  auto names_to_types_set = [&names_to_types](std::vector<std::string> const& names) {
    auto types = names_to_types(names);
    std::unordered_set<unsigned char> types_set {};
    std::transform(types.begin(), types.end(), std::inserter(types_set, types_set.end()), [](auto bt) {
      return static_cast<unsigned char>(bt);
    });
    return types_set;
  };

  auto setup_histogram = [this, &names_to_types](
                           std::vector<std::string>& names,
                           bin_mapping_t& mapping,
                           std::unique_ptr<gaudi_histo_t<1, float>>& histogram,
                           std::string histo_name) {
    auto types = names_to_types(names);
    names.clear();
    std::transform(
      types.begin(), types.end(), std::back_inserter(names), [](auto bt) { return LHCb::RawBank::typeName(bt); });

    mapping.fill(LHCb::RawBank::LastType);
    for (size_t i = 0; i < types.size(); ++i) {
      mapping[types[i]] = i;
    }

    histogram.reset(new gaudi_histo_t<1, float> {
      this,
      histo_name,
      histo_name,
      {static_cast<unsigned>(names.size()), -0.5f, names.size() - 0.5f, "Bank Type", names}});
  };

  for (auto const& [sd, bank_names] : sd_bank_types) {
    auto sd_type = bank_type(sd);
    if (sd_type == BankTypes::Unknown) {
      throw StrException {"Invalid SD specified: " + sd};
    }

    auto [it, s] = m_sd_info.emplace(sd, sd_info_t {});
    if (!s) {
      throw StrException {"Duplicate SD specified: " + sd};
    }

    data_names.insert(data_names.end(), bank_names.data_types.begin(), bank_names.data_types.end());
    other_names.insert(other_names.end(), bank_names.other_types.begin(), bank_names.other_types.end());
    error_names.insert(error_names.end(), bank_names.error_types.begin(), bank_names.error_types.end());

    auto sd_error_names = daq_error_types;
    sd_error_names.insert(sd_error_names.end(), bank_names.error_types.begin(), bank_names.error_types.end());
    auto sd_names = bank_names.data_types;
    sd_names.insert(sd_names.end(), bank_names.other_types.begin(), bank_names.other_types.end());
    sd_names.insert(sd_names.end(), sd_error_names.begin(), sd_error_names.end());

    auto& sd_info = it->second;
    sd_info.sd = sd_type;
    sd_info.data_bank_types = names_to_types_set(bank_names.data_types);
    sd_info.other_bank_types = names_to_types_set(bank_names.other_types);
    sd_info.error_bank_types = names_to_types_set(sd_error_names);
    setup_histogram(sd_names, sd_info.mapping, sd_info.banks, sd + "_banks");
    sd_info.error = std::make_unique<Gaudi::Accumulators::Counter<>>(this, "n_" + sd + "_error_banks");
    sd_info.invalid_type = std::make_unique<Gaudi::Accumulators::Counter<>>(this, "n_" + sd + "_invalid_bank_types");
  }

  // Setup the histograms that are filled based on the bank types
  for_each(
    std::tuple {
      std::tuple {
        std::ref(data_names), std::ref(m_data_bin_mapping), std::ref(m_data_banks), std::string {"n_data_banks"}},
      std::tuple {
        std::ref(other_names), std::ref(m_other_bin_mapping), std::ref(m_other_banks), std::string {"n_other_banks"}},
      std::tuple {
        std::ref(error_names), std::ref(m_error_bin_mapping), std::ref(m_error_banks), std::string {"n_error_banks"}}},
    [&setup_histogram](auto entry) {
      auto& names = std::get<0>(entry).get();
      auto& mapping = std::get<1>(entry).get();
      auto& histo = std::get<2>(entry);
      auto const& histo_name = std::get<3>(entry);
      setup_histogram(names, mapping, histo, histo_name);
    });

  // Setup the histogram that is filled on the top 5 bits of the
  // source IDs of the error banks
  for (uint16_t i = 0; i < SourceIdSys::SourceIdSys_TDET; ++i) {
    auto const* s = SourceId_sysstr(i << 11);
    if (s != nullptr) {
      source_names.push_back(s);
    }
    else {
      source_names.push_back("");
    }
  }

  m_error_per_source.reset(new gaudi_histo_t<1, float> {
    this,
    "error_banks_per_daq_source",
    "error_banks_per_daq_source",
    {static_cast<unsigned>(source_names.size()), -0.5f, source_names.size() - 0.5f, "DAQ Source", source_names}});
#endif
}

void error_bank_filter::error_bank_filter_t::operator()(
  ArgumentReferences<Parameters> const& arguments,
  RuntimeOptions const& runtime_options,
  Constants const&,
  Allen::Context const& context) const
{
  Allen::memset<host_output_event_list_t>(arguments, 0, context);

  host_function([this](Parameters parameters, RuntimeOptions const& runtime_options, unsigned number_of_events) {
    error_bank_filter(
      std::move(parameters),
      runtime_options.input_provider.get(),
      runtime_options.slice_index,
      number_of_events,
      std::get<0>(runtime_options.event_interval));
  })(arguments, runtime_options, size<host_event_list_t>(arguments));

  auto n_selected = first<host_number_of_selected_events_t>(arguments);
  reduce_size<host_output_event_list_t>(arguments, n_selected);
  reduce_size<dev_output_event_list_t>(arguments, n_selected);
  Allen::copy(
    get<dev_output_event_list_t>(arguments),
    get<host_output_event_list_t>(arguments),
    context,
    Allen::memcpyHostToDevice,
    n_selected);
}

void error_bank_filter::error_bank_filter_t::error_bank_filter(
  error_bank_filter::error_bank_filter_t::Parameters parameters,
  [[maybe_unused]] IInputProvider const* input_provider,
  [[maybe_unused]] unsigned const slice_index,
  unsigned const number_of_events,
  [[maybe_unused]] unsigned const event_start) const
{
  boost::dynamic_bitset<> selected_events {number_of_events};

#ifndef ALLEN_STANDALONE
  // Clear all temporary bin storage
  auto bin_storage = parameters.host_counts.get();
  std::memset(bin_storage.data(), 0, bin_storage.size_bytes());
  auto data_counts = bin_storage.subspan(0, LHCb::RawBank::LastType);
  auto other_counts = bin_storage.subspan(LHCb::RawBank::LastType, LHCb::RawBank::LastType);
  auto error_counts = bin_storage.subspan(2 * LHCb::RawBank::LastType, LHCb::RawBank::LastType);
  auto sd_counts = bin_storage.subspan(3 * LHCb::RawBank::LastType, LHCb::RawBank::LastType);
  // Don't need this many counts, but let's stick with it
  auto source_counts = bin_storage.subspan(4 * LHCb::RawBank::LastType, LHCb::RawBank::LastType);

  auto add_counts = [](gaudi_histo_t<1, float>& histo, gsl::span<float> counts) {
    for (size_t i = 0; i < histo.nBins(0); ++i) {
      histo[i] += counts[i];
    }
  };

  for (auto& [sd_name, sd_info] : m_sd_info) {
    std::memset(sd_counts.data(), 0, sd_counts.size_bytes());
    unsigned error_count = 0, invalid_count = 0;

    auto bno = input_provider->banks(sd_info.sd, slice_index);

    auto const version = bno.version;

    // Skip SDs that are not in the partition
    if (version == -1) continue;

    auto const& blocks = bno.fragments;
    auto const* types = bno.types.data();
    auto const* sizes = bno.sizes.data();
    auto const* offsets = bno.offsets.data();
    auto const mep_layout = parameters.mep_layout[0];

    auto const& data_bank_types = sd_info.data_bank_types;
    auto const& other_bank_types = sd_info.other_bank_types;
    auto const& error_bank_types = sd_info.error_bank_types;

    auto count_bank = [this,
                       sd_counts,
                       data_counts,
                       other_counts,
                       error_counts,
                       source_counts,
                       &error_count,
                       &invalid_count,
                       &data_bank_types,
                       &other_bank_types,
                       &error_bank_types,
                       &sd_info](uint8_t const bank_type, unsigned const source_id) {
      if (bank_type > LHCb::RawBank::BankType::LastType) {
        ++invalid_count;
        return false;
      }

      auto const sd_bin = sd_info.mapping[bank_type];
      ++sd_counts[sd_bin];

      if (data_bank_types.count(bank_type)) {
        auto const bin = m_data_bin_mapping[bank_type];
        ++data_counts[bin];
      }
      else if (other_bank_types.count(bank_type)) {
        auto const bin = m_other_bin_mapping[bank_type];
        ++other_counts[bin];
      }
      else if (error_bank_types.count(bank_type)) {
        ++error_count;
        auto const bin = m_error_bin_mapping[bank_type];
        ++error_counts[bin];
        ++source_counts[SourceId_sys(static_cast<uint16_t>(source_id & 0xFFFF))];
        return true;
      }
      return false;
    };

    if (mep_layout) {
      // In MEP layout for each bank index the bank types are stored
      // contiguously in memory for the entire batch of events, so the
      // inner loop should be over events.
      unsigned const number_of_banks = MEP::number_of_banks(offsets);
      for (unsigned bank_index = 0; bank_index < number_of_banks; ++bank_index) {
        for (unsigned event_index = 0; event_index < number_of_events; ++event_index) {
          auto const event_number = parameters.host_event_list[event_index];
          auto const raw_data_event_number = parameters.host_event_list[event_index] + event_start;
          auto const bank_type = MEP::bank_type(nullptr, types, raw_data_event_number, bank_index);
          auto const source_id = MEP::source_id(offsets, bank_index);
          selected_events[event_number] = count_bank(bank_type, source_id);
        }
      }
    }
    else {
      // In Allen layout the banks for a given event are adjecent to
      // each other in memory, so the inner loop should be over banks.
      auto const* raw_data = blocks[0].data();
      for (unsigned event_index = 0; event_index < number_of_events; ++event_index) {
        auto const event_number = parameters.host_event_list[event_index];
        auto const raw_data_event_number = parameters.host_event_list[event_index] + event_start;
        auto raw_event = Allen::RawEvent<false> {raw_data, offsets, sizes, types, raw_data_event_number};
        unsigned number_of_banks = Allen::number_of_banks(raw_data, offsets, raw_data_event_number);
        for (unsigned bank_index = 0; bank_index < number_of_banks; ++bank_index) {
          auto raw_bank = raw_event.raw_bank(bank_index);
          // Allen::bank_type(types, raw_data_event_number, bank_index);
          selected_events[event_number] = count_bank(raw_bank.type, raw_bank.source_id);
        }
      }
    }
    *sd_info.invalid_type += invalid_count;
    *sd_info.error += error_count;
    add_counts(*sd_info.banks, sd_counts);
  }

  for_each(
    std::tuple {std::tuple {m_data_banks.get(), data_counts},
                std::tuple {m_other_banks.get(), other_counts},
                std::tuple {m_error_banks.get(), error_counts},
                std::tuple {m_error_per_source.get(), source_counts}},
    [&add_counts](auto entry) {
      auto [histo, counts] = entry;
      add_counts(*histo, counts);
    });
#endif

  for (size_t i = 0, e = selected_events.find_first(); i < selected_events.count(); ++i) {
    parameters.host_output_event_list[i] = e;
    e = selected_events.find_next(e);
  }

  parameters.host_number_of_selected_events[0] = selected_events.count();
}

#ifndef ALLEN_STANDALONE
StatusCode Gaudi::Parsers::parse(error_bank_filter::bank_types_t& bt, const std::string& in)
{
  auto s = std::string_view {in};
  if (!s.empty() && s.front() == s.back() && (s.front() == '\'' || s.front() == '\"')) {
    s.remove_prefix(1);
    s.remove_suffix(1);
  }
  std::map<std::string, std::vector<std::string>> tmp;
  auto sc = parse(tmp, std::string {s});
  if (sc.isFailure()) return sc;

  try {
    for_each(
      std::tuple {std::tuple {std::string {"data_banks"}, std::ref(bt.data_types)},
                  std::tuple {std::string {"other_banks"}, std::ref(bt.other_types)},
                  std::tuple {std::string {"error_banks"}, std::ref(bt.error_types)}},
      [&tmp](auto entry) {
        auto const& k = std::get<0>(entry);
        auto& m = std::get<1>(entry).get();
        if (!tmp.count(k)) {
          throw StrException {"missing key" + k};
        }
        else {
          m = tmp[k];
        }
      });
    return StatusCode::SUCCESS;
  } catch (StrException const&) {
    return StatusCode::FAILURE;
  }
}
#endif
