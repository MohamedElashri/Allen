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
}

void error_bank_filter::error_bank_filter_t::init()
{
#ifndef ALLEN_STANDALONE
  std::map<std::string, bank_types_t> sd_bank_types = property<sd_bank_types_t>();
  std::vector<std::string> daq_error_types = property<daq_error_types_t>();

  std::vector<std::string> data_names, other_names, error_names = daq_error_types;

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
  IInputProvider const* input_provider,
  unsigned const slice_index,
  unsigned const number_of_events,
  unsigned const event_start) const
{
  boost::dynamic_bitset<> selected_events {number_of_events};

  for (auto& [sd_name, sd_info] : m_sd_info) {

    auto bno = input_provider->banks(sd_info.sd, slice_index);

    auto const version = bno.version;

    // Skip SDs that are not in the partition
    if (version == -1) continue;

    auto const& blocks = bno.fragments;
    auto const* types = bno.types.data();
    auto const* offsets = bno.offsets.data();
    auto const mep_layout = parameters.mep_layout[0];

#ifndef ALLEN_STANDALONE
    auto const& data_bank_types = sd_info.data_bank_types;
    auto const& other_bank_types = sd_info.other_bank_types;
#endif
    auto const& error_bank_types = sd_info.error_bank_types;

    for (unsigned event_index = 0; event_index < number_of_events; ++event_index) {
      auto event_number = parameters.host_event_list[event_index];
      auto raw_data_event_number = parameters.host_event_list[event_index] + event_start;

      unsigned number_of_banks = mep_layout ? MEP::number_of_banks(offsets) :
                                              Allen::number_of_banks(blocks[0].data(), offsets, raw_data_event_number);

      for (unsigned bank_index = 0; bank_index < number_of_banks; ++bank_index) {
        auto bank_type = parameters.mep_layout[0] ? MEP::bank_type(nullptr, types, raw_data_event_number, bank_index) :
                                                    Allen::bank_type(types, raw_data_event_number, bank_index);

        if (bank_type > LHCb::RawBank::BankType::LastType) {
#ifndef ALLEN_STANDALONE
          ++(*sd_info.invalid_type);
#endif
          continue;
        }

#ifndef ALLEN_STANDALONE
        auto const sd_bin = sd_info.mapping[bank_type];
        ++(*sd_info.banks)[sd_bin];

        if (data_bank_types.count(bank_type)) {
          auto const bin = m_data_bin_mapping[bank_type];
          ++(*m_data_banks)[bin];
        }
        else if (other_bank_types.count(bank_type)) {
          auto const bin = m_other_bin_mapping[bank_type];
          ++(*m_other_banks)[bin];
        }
        else
#endif
          if (error_bank_types.count(bank_type)) {
#ifndef ALLEN_STANDALONE
          ++(*sd_info.error);
          auto const bin = m_error_bin_mapping[bank_type];
          ++(*m_error_banks)[bin];
#endif
          selected_events[event_number] = true;
        }
      }
    }
  }

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
