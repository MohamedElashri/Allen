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
#ifndef INPUTREADER_H
#define INPUTREADER_H 1

#include "Common.h"
#include "BankTypes.h"
#include <string>
#include <algorithm>
#include <unordered_set>
#include <gsl/gsl>
#include "nlohmann/json.hpp"
#include "Configuration.h"

struct Reader {
  std::string folder_name;

  /**
   * @brief Sets the folder name parameter and check the folder exists.
   */
  Reader(const std::string& folder_name);
};

struct GeometryReader : public Reader {
  GeometryReader(const std::string& folder_name) : Reader(folder_name) {}

  /**
   * @brief Reads a geometry file from the specified folder.
   */
  std::vector<char> read_geometry(const std::string& filename) const;
};

using FolderMap = std::map<BankTypes, std::string>;

struct ConfigurationReader {

  using Params = std::map<std::string, std::map<std::string, nlohmann::json>>;

  ConfigurationReader(std::string_view configuration);
  ConfigurationReader(const Params& params) : m_params(params) {}

  std::map<std::string, nlohmann::json> params(std::string key) const
  {
    return (m_params.count(key) > 0 ? m_params.at(key) : std::map<std::string, nlohmann::json>());
  }

  Params const& params() const { return m_params; }
  ConfiguredSequence const& configured_sequence() const { return m_configured_sequence; }

  void save(std::string file_name);

  std::map<std::string, nlohmann::json> get_sequence() const;

  std::unordered_set<BankTypes> configured_bank_types() const;

private:
  std::map<std::string, std::map<std::string, nlohmann::json>> m_params;
  std::map<std::string, nlohmann::json> m_sequence;
  ConfiguredSequence m_configured_sequence;
};

bool compatible_configurations(ConfigurationReader const& a, ConfigurationReader const& b);

#endif
