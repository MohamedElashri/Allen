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
#include "TwoTrackEvaluator.cuh"

INSTANTIATE_ALGORITHM(two_track_evaluator::two_track_evaluator_t)

void two_track_evaluator::two_track_evaluator_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_two_track_catboost_evaluation_t>(arguments, first<host_number_of_svs_t>(arguments));
}

void two_track_evaluator::two_track_evaluator_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  HostBuffers&,
  const Allen::Context& context) const
{
  const int block_dim = 64;
  const auto grid_dim = dim3((first<host_number_of_svs_t>(arguments) + block_dim - 1) / block_dim);

  global_function(two_track_evaluator)(grid_dim, dim3(block_dim), context)(
    arguments,
    constants.dev_two_track_catboost_leaf_values,
    constants.dev_two_track_catboost_leaf_offsets,
    constants.dev_two_track_catboost_split_borders,
    constants.dev_two_track_catboost_split_features,
    constants.dev_two_track_catboost_tree_depths,
    constants.dev_two_track_catboost_tree_offsets,
    constants.two_track_catboost_n_trees,
    first<host_number_of_svs_t>(arguments));
}

__global__ void two_track_evaluator::two_track_evaluator(
  two_track_evaluator::Parameters parameters,
  const float* leaf_values,
  const int* leaf_offsets,
  const float* split_borders,
  const int* split_features,
  const int* tree_sizes,
  const int* tree_offsets,
  const int n_trees,
  const int n_objects)
{
  for (unsigned object_id = blockIdx.x * blockDim.x + threadIdx.x; object_id < n_objects;
       object_id += blockDim.x * gridDim.x) {
    float sum = 0;
    const int object_offset = object_id * 4;

    for (unsigned tree_id = 0; tree_id < n_trees; tree_id++) {
      int index = 0;
      const int tree_offset = tree_offsets[tree_id];
      for (int depth = 0; depth < 8; ++depth) {
        if (depth >= tree_sizes[tree_id]) break;
        const int feature_id = split_features[tree_offset + depth];
        const float feature_value = parameters.dev_two_track_catboost_preprocess_output[object_offset + feature_id];
        const float border = split_borders[tree_offset + depth];
        if (feature_value > border) index |= (1 << depth);
      }
      sum += leaf_values[leaf_offsets[tree_id] + index];
    }
    parameters.dev_two_track_catboost_evaluation[object_id] = sum;
  }
}
