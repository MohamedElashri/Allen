/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#pragma once

#include <vector>
#include <string>
#include <iostream>
#include <map>

/**
 * @brief Options accepted in the program.
 * @details Each argument is composed of the following:
 *
 *          options: vector of strings with all names to arguments.
 *          description: description of arguments, shown in print_usage.
 *          default_value [optional]: default value the argument takes.
 */
struct ProgramOption {
  std::vector<std::string> options;
  std::string description;
  std::string default_value = "";
  std::string description_default_value = "";

  ProgramOption() = default;
  ProgramOption(const std::vector<std::string>&& options, const std::string&& description) :
    options(options), description(description)
  {}
  ProgramOption(
    const std::vector<std::string>&& options,
    const std::string&& description,
    const std::string&& default_value) :
    options(options),
    description(description), default_value(default_value)
  {}
  ProgramOption(
    const std::vector<std::string>&& options,
    const std::string&& description,
    const std::string&& default_value,
    const std::string&& description_default_value) :
    options(options),
    description(description), default_value(default_value), description_default_value(description_default_value)
  {}
};

/**
 * @brief Prints usage of the application according to program options.
 */
void print_usage(char* argv[], const std::vector<ProgramOption>& program_options);

std::vector<ProgramOption> allen_program_options();

void print_call_options(const std::map<std::string, std::string>& options, const std::string& device_name);

std::vector<std::string> split_string(std::string const& input, std::string const& sep);

std::tuple<bool, std::map<std::string, int>> parse_receivers(const std::string& arg);
