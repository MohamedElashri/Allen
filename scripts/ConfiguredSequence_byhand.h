#pragma once

#include <vector>
#include <string>

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

struct ConfiguredAlgorithm {
  std::string id;
  std::string name;
};

struct ConfiguredArgument {
  std::string scope;
  std::string name;
};

struct ConfiguredAlgorithmArguments {
  std::vector<std::string> arguments;
  std::vector<std::vector<std::string>> input_aggregates;
  std::vector<std::string> dependencies;
};

struct Dependencies {
  std::vector<std::string> arguments;
};

// ArgumentData creator
ArgumentData create_allen_argument(const ConfiguredArgument& alg) {
  if (alg.scope == "host" || alg.scope == "device") {
    return ArgumentData{alg.scope, alg.name};
  } else {
    throw ArgumentScopeNotSupportedException{alg.scope};
  }
}

// Get in and out dependencies
std::tuple<std::vector<Dependencies>, std::vector<Dependencies>> calculate_dependencies(const std::vector<ConfiguredAlgorithmArguments>& sequence_arguments) {
  std::vector<Dependencies> in_deps;
  std::vector<Dependencies> out_deps;
  std::vector<std::string> temp_arguments;

  const auto argument_in = [] (const std::string& arg, const std::vector<std::string>& args) {
    return std::find(std::begin(args), std::end(args), arg) != std::end(args);
  };

  for (unsigned i = 0; i < sequence_arguments.size(); ++i) {
    // Calculate out_dep for this algorithm
    Dependencies out_dep;
    std::vector<std::string> next_temp_arguments;
    for (const auto& arg : temp_arguments) {
      bool arg_can_be_freed = true;

      for (unsigned j = i; j < sequence_arguments.size(); ++j) {
        const auto& alg = sequence_arguments[j];
        if (argument_in(arg, alg.arguments) || argument_in(arg, alg.dependencies)) {
          arg_can_be_freed = false;
          break;
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
      } else {
        next_temp_arguments.push_back(arg);
      }
    }
    out_deps.emplace_back(out_dep);

    // Update temp_arguments
    temp_arguments = next_temp_arguments;

    // Calculate in_dep for this algorithm
    Dependencies in_dep;
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

// -------------
// Generate this
// -------------

// Forward declare the algorithms that we are interested in
namespace host_init_event_list {
  struct host_init_event_list_t;
}
namespace host_data_provider {
  struct host_data_provider_t;
}

// Algorithm instantiator
Allen::TypeErasedAlgorithm instantiate_allen_algorithm(const ConfiguredAlgorithm& alg) {
  if (alg.id == "host_init_event_list::host_init_event_list_t") {
    return Allen::instantiate_algorithm<host_init_event_list::host_init_event_list_t>(alg.name);
  } else if (alg.id == "host_data_provider::host_data_provider_t") {
    return Allen::instantiate_algorithm<host_data_provider::host_data_provider_t>(alg.name);
  } else {
    throw AlgorithmNotExportedException{alg.id};
  }
}

// ------------------------------------------------
// This will be done at runtime by reading the json
// ------------------------------------------------

std::vector<ConfiguredAlgorithm> get_configured_algorithms() {
  return {
    {"host_init_event_list::host_init_event_list_t", "initialize_event_lists"},
    {"host_data_provider::host_data_provider_t", "host_scifi_banks"}
  };
}

std::vector<ConfiguredArgument> get_configured_arguments() {
  return {
    {"host", "initialize_event_lists__host_event_list_output_t"},
    {"device", "initialize_event_lists__dev_event_list_output_t"},
    {"host", "host_scifi_banks__host_raw_banks_t"},
    {"host", "host_scifi_banks__host_raw_offsets_t"},
    {"host", "host_scifi_banks__host_raw_bank_version_t"}
  };
}

std::vector<ConfiguredAlgorithmArguments> get_configured_sequence_arguments() {
  return {
    {{"initialize_event_lists__host_event_list_output_t", "initialize_event_lists__dev_event_list_output_t"}, {}, {}},
    {{"host_scifi_banks__host_raw_banks_t", "host_scifi_banks__host_raw_offsets_t", "host_scifi_banks__host_raw_bank_version_t"}, {}, {}}
  };
}
