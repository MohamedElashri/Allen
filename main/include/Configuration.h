/*****************************************************************************\
* (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include <stdexcept>
#include <vector>
#include <string>

struct ConfiguredAlgorithm {
  std::string id;
  std::string name;
  std::string scope;

  ConfiguredAlgorithm(const std::string& id, const std::string& name, const std::string& scope) :
    id(id), name(name), scope(scope)
  {}
};

struct ConfiguredArgument {
  std::string scope;
  std::string name;

  ConfiguredArgument(const std::string& scope, const std::string& name) : scope(scope), name(name) {}
};

struct ConfiguredAlgorithmArguments {
  std::vector<std::string> arguments;
  std::vector<std::vector<std::string>> input_aggregates;

  ConfiguredAlgorithmArguments(
    const std::vector<std::string>& arguments,
    const std::vector<std::vector<std::string>>& input_aggregates) :
    arguments(arguments),
    input_aggregates(input_aggregates)
  {}
};

using ArgumentDependencies = std::map<std::string, std::vector<std::string>>;

struct LifetimeDependencies {
  std::vector<std::string> arguments;
};

struct ConfiguredSequence {
  std::vector<ConfiguredAlgorithm> configured_algorithms;
  std::vector<ConfiguredArgument> configured_arguments;
  std::vector<ConfiguredAlgorithmArguments> configured_algorithm_arguments;
  ArgumentDependencies argument_dependencies;
};

struct ParsedSequence {
  using configured_algorithm_parse_t = std::vector<std::tuple<std::string, std::string, std::string>>;
  using configured_argument_parse_t = std::vector<std::tuple<std::string, std::string>>;
  using configured_algorithm_argument_parse_t =
    std::vector<std::tuple<std::vector<std::string>, std::vector<std::vector<std::string>>>>;
  using argument_dependencies_parse_t = ArgumentDependencies;

  template<typename T, typename U>
  static std::vector<T> to_configured(const U& parsed)
  {
    std::vector<T> configured;
    for (const auto& element : parsed) {
      configured.emplace_back(std::make_from_tuple<T>(element));
    }
    return configured;
  }
};

struct AlgorithmNotExportedException : public std::exception {
private:
  std::string m_exception_text;

public:
  AlgorithmNotExportedException(const std::string& alg_id) :
    m_exception_text("Requested algorithm id not found: " + alg_id)
  {}
  const char* what() const noexcept override { return m_exception_text.c_str(); }
};

struct ArgumentScopeNotSupportedException : public std::exception {
private:
  std::string m_exception_text;

public:
  ArgumentScopeNotSupportedException(const std::string& scope) :
    m_exception_text("Requested argument scope not supported: " + scope)
  {}
  const char* what() const noexcept override { return m_exception_text.c_str(); }
};
