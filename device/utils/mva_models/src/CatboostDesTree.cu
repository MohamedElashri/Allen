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
#include "CatboostDesTree.cuh"

namespace {

  template<typename T>
  inline void copy_to_data(gsl::span<char> dst, std::vector<T> src, unsigned& offset)
  {
    memcpy(dst.data() + offset, src.data(), sizeof(T) * src.size());
    offset += sizeof(T) * src.size();
  }

  template<typename T>
  inline void copy_to_data(gsl::span<char> dst, T src, unsigned& offset)
  {
    *(reinterpret_cast<T*>(dst.data() + offset)) = src;
    offset += sizeof(T);
  }

} // namespace

void Allen::MVAModels::CatboostDT::readData(std::string parameters_path)
{

  auto data_to_copy = readCatBoostJSON(parameters_path + m_path);

  std::vector<unsigned> host_offsets;
  host_offsets.reserve(8);

  unsigned total_size = 0;
  host_offsets.emplace_back(total_size);
  total_size += sizeof(unsigned);
  host_offsets.emplace_back(total_size);
  total_size += sizeof(unsigned);
  host_offsets.emplace_back(total_size);
  total_size += sizeof(unsigned) * data_to_copy.number_of_trees;
  host_offsets.emplace_back(total_size);
  total_size += sizeof(unsigned) * (data_to_copy.number_of_trees + 1);
  host_offsets.emplace_back(total_size);
  total_size += sizeof(unsigned) * (data_to_copy.number_of_trees + 1);
  host_offsets.emplace_back(total_size);
  total_size += data_to_copy.total_leaf_values_size * sizeof(float);
  host_offsets.emplace_back(total_size);
  total_size += data_to_copy.total_split_border_size * sizeof(float);
  host_offsets.emplace_back(total_size);
  total_size += data_to_copy.total_split_feature_size * sizeof(unsigned);

  std::vector<char> host_data(total_size);

  unsigned leaf_values_offset = host_offsets[5];
  unsigned split_border_offset = host_offsets[6];
  unsigned split_feature_offset = host_offsets[7];

  copy_to_data(host_data, data_to_copy.host_leaf_values, leaf_values_offset);
  copy_to_data(host_data, data_to_copy.host_tree_split_borders, split_border_offset);
  copy_to_data(host_data, data_to_copy.host_tree_split_features, split_feature_offset);

  unsigned number_of_trees_offset = host_offsets[0];
  unsigned num_features_offset = host_offsets[1];
  unsigned tree_depth_offset = host_offsets[2];
  unsigned tree_offsets_offset = host_offsets[3];
  unsigned leaf_offset_offset = host_offsets[4];

  copy_to_data(host_data, data_to_copy.number_of_trees, number_of_trees_offset);
  copy_to_data(host_data, data_to_copy.num_features, num_features_offset);
  copy_to_data(host_data, data_to_copy.tree_depth, tree_depth_offset);
  copy_to_data(host_data, data_to_copy.tree_offsets, tree_offsets_offset);
  copy_to_data(host_data, data_to_copy.leaf_offset, leaf_offset_offset);

  Allen::malloc((void**) &(m_device_view.m_data), total_size);
  Allen::memcpy(m_device_view.m_data, host_data.data(), total_size, Allen::memcpyHostToDevice);

  Allen::malloc((void**) &(m_device_view.m_offsets), host_offsets.size() * sizeof(unsigned));
  Allen::memcpy(
    m_device_view.m_offsets, host_offsets.data(), host_offsets.size() * sizeof(unsigned), Allen::memcpyHostToDevice);
}