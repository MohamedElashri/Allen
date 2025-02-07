/*****************************************************************************\
* (c) Copyright 2024 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once
#include "MVAModelsManager.h"
#include "InputReader.h"
#include "BackendCommon.h"
#include <boost/algorithm/string.hpp>
#include <fstream>

namespace Allen::MVAModels {

  struct CatBoostData {
    std::vector<unsigned> tree_depth;
    std::vector<unsigned> tree_offsets;
    std::vector<unsigned> leaf_offset;

    unsigned number_of_trees;
    unsigned num_features;

    unsigned total_leaf_values_size;
    unsigned total_split_border_size;
    unsigned total_split_feature_size;

    std::vector<float> host_tree_split_borders;
    std::vector<unsigned> host_tree_split_features;
    std::vector<float> host_leaf_values;
  };

  inline CatBoostData readCatBoostJSON(std::string full_path)
  {

    CatBoostData to_copy;

    nlohmann::json j;
    {
      std::ifstream i(full_path);
      j = nlohmann::json::parse(i);
    }

    unsigned number_of_trees = j["oblivious_trees"].size();
    unsigned num_features = j["features_info"]["float_features"].size();

    to_copy.tree_depth.reserve(number_of_trees);
    to_copy.tree_offsets.reserve(number_of_trees + 1);
    to_copy.leaf_offset.reserve(number_of_trees + 1);

    to_copy.tree_offsets.emplace_back(0);
    to_copy.leaf_offset.emplace_back(0);

    to_copy.total_leaf_values_size = 0;
    to_copy.total_split_border_size = 0;
    to_copy.total_split_feature_size = 0;

    for (const auto& tree : j["oblivious_trees"]) {
      to_copy.total_leaf_values_size += tree["leaf_values"].size();
      to_copy.total_split_border_size += tree["splits"].size();
      to_copy.total_split_feature_size += tree["splits"].size();
    }

    to_copy.number_of_trees = number_of_trees;
    to_copy.num_features = num_features;

    for (const auto& tree : j["oblivious_trees"]) {
      unsigned tree_depth_size = tree["splits"].size();
      to_copy.tree_depth.emplace_back(tree_depth_size);
      to_copy.tree_offsets.emplace_back(to_copy.tree_offsets.back() + tree_depth_size);
      to_copy.leaf_offset.emplace_back(to_copy.leaf_offset.back() + (1 << tree_depth_size));

      const auto leaf_values = tree["leaf_values"].get<std::vector<float>>();
      to_copy.host_leaf_values.insert(to_copy.host_leaf_values.end(), leaf_values.begin(), leaf_values.end());

      std::vector<float> tree_split_borders;
      std::vector<unsigned> tree_split_features;
      tree_split_borders.reserve(tree["splits"].size());
      tree_split_features.reserve(tree["splits"].size());

      for (const auto& split : tree["splits"]) {
        float border = split["border"].get<float>();
        unsigned feature = split["float_feature_index"].get<unsigned>();

        tree_split_borders.emplace_back(border);
        tree_split_features.emplace_back(feature);
      }

      to_copy.host_tree_split_borders.insert(
        to_copy.host_tree_split_borders.end(), tree_split_borders.begin(), tree_split_borders.end());
      to_copy.host_tree_split_features.insert(
        to_copy.host_tree_split_features.end(), tree_split_features.begin(), tree_split_features.end());
    }

    return to_copy;
  }
  struct CatboostDTDevice {
    char* m_data = nullptr;
    unsigned* m_offsets = nullptr;

    __device__ unsigned* n_features() const { return (unsigned*) (m_data + m_offsets[0]); }

    __device__ unsigned* n_trees() const { return (unsigned*) (m_data + m_offsets[1]); }

    __device__ unsigned* tree_depths() const { return (unsigned*) (m_data + m_offsets[2]); }

    __device__ unsigned* tree_offsets() const { return (unsigned*) (m_data + m_offsets[3]); }

    __device__ unsigned* leaf_offsets() const { return (unsigned*) (m_data + m_offsets[4]); }

    __device__ float* leaf_values() const { return (float*) (m_data + m_offsets[5]); }

    __device__ float* split_borders() const { return (float*) (m_data + m_offsets[6]); }

    __device__ unsigned* split_features() const { return (unsigned*) (m_data + m_offsets[7]); }
  };

  struct CatboostDT : public MVAModelBase {
    using DeviceType = CatboostDTDevice;

    CatboostDT(std::string name, std::string path) : MVAModelBase(name, path) {}

    const DeviceType* getDevicePointer() const { return &m_device_view; }

    const auto& getDeviceView() const { return m_device_view; }

    void readData(std::string parameters_path) override;

  private:
    DeviceType m_device_view;
  };
} // namespace Allen::MVAModels