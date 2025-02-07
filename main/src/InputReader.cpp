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
#include <gsl/gsl>
#include <InputReader.h>
#include <boost/algorithm/string.hpp>
#include "InputTools.h"
#include "Tools.h"

#include <range/v3/algorithm/all_of.hpp>
#include <range/v3/core.hpp>
#include <range/v3/numeric/accumulate.hpp>
#include <range/v3/view/take.hpp>
#include <range/v3/view/map.hpp>
#include <range/v3/view/zip.hpp>
#include <range/v3/algorithm/equal.hpp>

namespace {
  using std::make_pair;
}

Reader::Reader(const std::string& folder_name) : folder_name(folder_name)
{
  if (!exists_test(folder_name)) {
    throw StrException("Folder " + folder_name + " does not exist.");
  }
}

std::vector<char> GeometryReader::read_geometry(const std::string& filename) const
{
  std::vector<char> geometry;
  ::read_geometry(folder_name + "/" + filename, geometry);
  return geometry;
}

ConfigurationReader::ConfigurationReader(std::string_view configuration)
{
  nlohmann::json j = nlohmann::json::parse(configuration);
  for (auto& el : j.items()) {
    std::string component = el.key();
    if (component == "sequence") {
      m_sequence = {};
      for (auto& el2 : el.value().items()) {
        if (el2.key() == "configured_algorithms") {
          m_sequence[el2.key()] = el2.value();
          m_configured_sequence.configured_algorithms = ParsedSequence::to_configured<ConfiguredAlgorithm>(
            el2.value().get<ParsedSequence::configured_algorithm_parse_t>());
        }
        else if (el2.key() == "configured_arguments") {
          m_sequence[el2.key()] = el2.value();
          m_configured_sequence.configured_arguments = ParsedSequence::to_configured<ConfiguredArgument>(
            el2.value().get<ParsedSequence::configured_argument_parse_t>());
        }
        else if (el2.key() == "configured_sequence_arguments") {
          m_sequence[el2.key()] = el2.value();
          m_configured_sequence.configured_algorithm_arguments =
            ParsedSequence::to_configured<ConfiguredAlgorithmArguments>(
              el2.value().get<ParsedSequence::configured_algorithm_argument_parse_t>());
        }
        else if (el2.key() == "argument_dependencies") {
          m_sequence[el2.key()] = el2.value();
          m_configured_sequence.argument_dependencies =
            el2.value().get<ParsedSequence::argument_dependencies_parse_t>();
        }
      }
    }
    else {
      for (auto& el2 : el.value().items()) {
        std::string property = el2.key();
        m_params[component][property] = el2.value();
      }
    }
  }

  if (logger::verbosity() >= logger::verbose) {
    for (auto it = m_params.begin(); it != m_params.end(); ++it) {
      for (auto it2 = (*it).second.begin(); it2 != (*it).second.end(); ++it2) {
        verbose_cout << (*it).first << ":" << (*it2).first << ":" << (*it2).second << std::endl;
      }
    }
  }
}

std::map<std::string, nlohmann::json> ConfigurationReader::get_sequence() const { return m_sequence; }

void ConfigurationReader::save(std::string file_name)
{
  using json_float = nlohmann::basic_json<std::map, std::vector, std::string, bool, std::int32_t, std::uint32_t, float>;
  json_float j;
  for (auto [alg, props] : m_params) {
    for (auto [k, v] : props) {
      j[alg][k] = v;
    }
  }
  std::ofstream o(file_name);
  o << std::setw(4) << j;
  o.close();
}

std::unordered_set<BankTypes> ConfigurationReader::configured_bank_types() const
{
  // Bank types
  std::unordered_set<BankTypes> bank_types = {BankTypes::ODIN};

  std::vector<std::string> provider_algorithms;
  for (const auto& alg : m_configured_sequence.configured_algorithms) {
    if (alg.scope == "ProviderAlgorithm") {
      provider_algorithms.push_back(alg.name);
    }
  }

  for (const auto& provider_alg : provider_algorithms) {
    const auto props = m_params.at(provider_alg);
    auto it_type = props.find("bank_type");
    auto it_empty = props.find("empty");
    if (it_type != props.end()) {
      auto type = it_type->second;
      auto const bt = ::bank_type(type);
      if (bt == BankTypes::Unknown) {
        error_cout << "Unknown bank type " << type << " requested.\n";
      }
      else if (it_empty == props.end() || !it_empty->second.get<bool>()) {
        bank_types.emplace(bt);
      }
    }
  }

  return bank_types;
}

bool compatible_configurations(ConfigurationReader const& a, ConfigurationReader const& b)
{
  // For two configurations to be compatible, their sequences must be
  // the same and all algorithms must have the same properties. Values
  // of properties may be different.
  using namespace ranges;

  auto const &a_pars = a.params(), b_pars = b.params();
  return a.configured_sequence() == b.configured_sequence() &&
         ranges::equal(views::keys(a_pars), views::keys(b_pars)) &&
         ranges::all_of(views::zip(a_pars, b_pars), [](auto&& entry) {
           auto const& [a, b] = entry;
           return ranges::equal(views::keys(a.second), views::keys(b.second));
         });
}