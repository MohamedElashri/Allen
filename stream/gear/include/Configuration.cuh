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
#include "ArgumentManager.cuh"

struct ConfiguredAlgorithm {
  std::string id;
  std::string name;

  ConfiguredAlgorithm(const std::string& id, const std::string& name) : id(id), name(name) {}
};

struct ConfiguredArgument {
  std::string scope;
  std::string name;

  ConfiguredArgument(const std::string& scope, const std::string& name) : scope(scope), name(name) {}
};

struct ConfiguredAlgorithmArguments {
  std::vector<std::string> arguments;
  std::vector<std::vector<std::string>> input_aggregates;

  ConfiguredAlgorithmArguments(const std::vector<std::string>& arguments, const std::vector<std::vector<std::string>>& input_aggregates) :
    arguments(arguments), input_aggregates(input_aggregates) {}
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
  using configured_algorithm_parse_t = std::vector<std::tuple<std::string, std::string>>;
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

// ArgumentData creator
inline ArgumentData create_allen_argument(const ConfiguredArgument& alg)
{
  if (alg.scope == "host") {
    return ArgumentData {alg.name, ArgumentScope::Host};
  } else if (alg.scope == "device") {
    return ArgumentData {alg.name, ArgumentScope::Device};
  }
  else {
    throw ArgumentScopeNotSupportedException {alg.scope};
  }
}

// Get in and out dependencies
inline std::tuple<std::vector<LifetimeDependencies>, std::vector<LifetimeDependencies>> calculate_lifetime_dependencies(
  const std::vector<ConfiguredAlgorithmArguments>& sequence_arguments,
  const ArgumentDependencies& argument_dependencies)
{
  std::vector<LifetimeDependencies> in_deps;
  std::vector<LifetimeDependencies> out_deps;
  std::vector<std::string> temp_arguments;

  const auto argument_in = [](const std::string& arg, const auto& args) {
    return std::find(std::begin(args), std::end(args), arg) != std::end(args);
  };

  const auto argument_in_map = [](const std::string& arg, const auto& args) {
    return args.find(arg) != std::end(args);
  };

  for (unsigned i = 0; i < sequence_arguments.size(); ++i) {
    // Calculate out_dep for this algorithm
    LifetimeDependencies out_dep;
    std::vector<std::string> next_temp_arguments;
    for (const auto& arg : temp_arguments) {
      bool arg_can_be_freed = true;

      for (unsigned j = i; j < sequence_arguments.size(); ++j) {
        const auto& alg = sequence_arguments[j];
        if (argument_in(arg, alg.arguments)) {
          arg_can_be_freed = false;
          break;
        }

        // dependencies
        for (const auto& alg_arg : alg.arguments) {
          if (argument_in_map(alg_arg, argument_dependencies) && argument_in(arg, argument_dependencies.at(alg_arg))) {
            arg_can_be_freed = false;
            break;
          }
        }

        // input aggregates
        for (const auto& input_aggregate : alg.input_aggregates) {
          if (argument_in(arg, input_aggregate)) {
            arg_can_be_freed = false;
            break;
          }
        }
      }

      if (arg_can_be_freed) {
        out_dep.arguments.push_back(arg);
      }
      else {
        next_temp_arguments.push_back(arg);
      }
    }
    out_deps.emplace_back(out_dep);

    // Update temp_arguments
    temp_arguments = next_temp_arguments;

    // Calculate in_dep for this algorithm
    LifetimeDependencies in_dep;
    for (const auto& arg : sequence_arguments[i].arguments) {
      if (!argument_in(arg, temp_arguments)) {
        temp_arguments.push_back(arg);
        in_dep.arguments.push_back(arg);
      }
    }
    in_deps.emplace_back(in_dep);
  }

  return {in_deps, out_deps};
}
