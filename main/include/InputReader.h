#ifndef INPUTREADER_H
#define INPUTREADER_H 1

#include "InputTools.h"
#include "Common.h"
#include "BankTypes.h"
#include "Tools.h"
#include <string>
#include <algorithm>
#include <unordered_set>
#include <gsl/gsl>
#include "nlohmann/json.hpp"

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

struct EventReader : public Reader {
  EventReader(FolderMap folders) : Reader(begin(folders)->second), m_folders {std::move(folders)} {}

  virtual ~EventReader() = default;

  gsl::span<char> events(BankTypes type)
  {
    auto it = m_events.find(type);
    if (it == end(m_events)) {
      return {};
    }
    else {
      return it->second.first;
    }
  }

  gsl::span<unsigned> offsets(BankTypes type)
  {
    auto it = m_events.find(type);
    if (it == end(m_events)) {
      return {};
    }
    else {
      return it->second.second;
    }
  }

  /**
   * @brief Reads files from the specified folder, starting from an event offset.
   */
  virtual std::vector<std::tuple<unsigned int, unsigned long>> read_events(
    unsigned number_of_events_requested = 0,
    unsigned start_event_offset = 0);

  /**
   * @brief Checks the consistency of the read buffers.
   */
  virtual bool check_events(
    BankTypes type,
    const std::vector<char>& events,
    const std::vector<unsigned>& event_offsets,
    unsigned number_of_events_requested) const;

protected:
  std::string folder(BankTypes type) const
  {
    auto it = m_folders.find(type);
    if (it == end(m_folders)) {
      return {};
    }
    else {
      return it->second;
    }
  }

  std::unordered_set<BankTypes> types() const
  {
    std::unordered_set<BankTypes> r;
    for (const auto& entry : m_folders) {
      r.emplace(entry.first);
    }
    return r;
  }

  bool add_events(BankTypes type, gsl::span<char> events, gsl::span<unsigned> offsets)
  {
    auto r = m_events.emplace(type, std::make_pair(std::move(events), std::move(offsets)));
    return r.second;
  }

private:
  std::map<BankTypes, std::pair<gsl::span<char>, gsl::span<unsigned>>> m_events;
  std::map<BankTypes, std::string> m_folders;
};

struct CatboostModelReader {
  CatboostModelReader(const std::string& file_name);
  int n_features() const { return m_num_features; }
  int n_trees() const { return m_num_trees; }
  std::vector<int> tree_depths() const { return m_tree_depths; }
  std::vector<int> tree_offsets() const { return m_tree_offsets; }
  std::vector<int> leaf_offsets() const { return m_leaf_offsets; }
  std::vector<float> leaf_values() const { return m_leaf_values; }
  std::vector<float> split_border() const { return m_split_border; }
  std::vector<int> split_feature() const { return m_split_feature; }

private:
  int m_num_features;
  int m_num_trees;
  std::vector<int> m_tree_depths;
  std::vector<int> m_tree_offsets;
  std::vector<int> m_leaf_offsets;
  std::vector<float> m_leaf_values;
  std::vector<float> m_split_border;
  std::vector<int> m_split_feature;
};

struct ConfigurationReader {
  ConfigurationReader(const std::string& file_name);
  ConfigurationReader(const std::map<std::string, std::map<std::string, std::string>>& params) : m_params(params) {}

  std::map<std::string, std::string> params(std::string key) const
  {
    return (m_params.count(key) > 0 ? m_params.at(key) : std::map<std::string, std::string>());
  }
  std::map<std::string, std::map<std::string, std::string>> params() const { return m_params; }

  void save(std::string file_name);

private:
  std::map<std::string, std::map<std::string, std::string>> m_params;
};

#endif
