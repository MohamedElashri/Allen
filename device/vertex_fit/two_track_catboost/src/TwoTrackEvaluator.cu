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
  global_function(two_track_evaluator)(dim3(first<host_number_of_svs_t>(arguments)), property<block_dim_t>(), context)(
    arguments,
    constants.dev_two_track_catboost_leaf_values,
    constants.dev_two_track_catboost_leaf_offsets,
    constants.dev_two_track_catboost_split_borders,
    constants.dev_two_track_catboost_split_features,
    constants.dev_two_track_catboost_tree_depths,
    constants.dev_two_track_catboost_tree_offsets,
    constants.two_track_catboost_n_trees);
}

__global__ void two_track_evaluator::two_track_evaluator(
  two_track_evaluator::Parameters parameters,
  const float* leaf_values,
  const int* leaf_offsets,
  const float* split_borders,
  const int* split_features,
  const int* tree_sizes,
  const int* tree_offsets,
  const int n_trees)
{
  const auto object_id = blockIdx.x;
  const auto block_size = blockDim.x;
  int tree_id = threadIdx.x;
  float sum = 0;

  const int object_offset = object_id * 4;

  while (tree_id < n_trees) {
    int index = 0;
    const int tree_offset = tree_offsets[tree_id];
    for (int depth = 0; depth < tree_sizes[tree_id]; ++depth) {
      const int feature_id = split_features[tree_offset + depth];
      const float feature_value = parameters.dev_two_track_catboost_preprocess_output[object_offset + feature_id];
      const float border = split_borders[tree_offset + depth];
      const int bin_feature = (int) (feature_value > border);
      index |= (bin_feature << depth);
    }
    sum += leaf_values[leaf_offsets[tree_id] + index];
    tree_id += block_size;
  }

  __shared__ float values[256];

  int tid = threadIdx.x;
  values[tid] = sum;
  __syncthreads();
  for (int s = block_size / 2; s > 0; s >>= 1) {
    if (tid < s) values[tid] += values[tid + s];
    __syncthreads();
  }

  if (threadIdx.x == 0) {
    parameters.dev_two_track_catboost_evaluation[object_id] = values[0];
  }
}
