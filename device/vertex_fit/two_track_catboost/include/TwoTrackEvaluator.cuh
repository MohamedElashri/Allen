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

#include "AlgorithmTypes.cuh"
#include <cmath>

namespace two_track_evaluator {

  struct Parameters {
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_two_track_catboost_preprocess_output_t, float) dev_two_track_catboost_preprocess_output;
    DEVICE_OUTPUT(dev_two_track_catboost_evaluation_t, float) dev_two_track_catboost_evaluation;
    PROPERTY(block_dim_t, "block_dim", "block dimension", DeviceDimensions) block_dim;
  };

  __global__ void two_track_evaluator(
    Parameters,
    const float* leaf_values,
    const int* leaf_offsets,
    const float* split_borders,
    const int* split_features,
    const int* tree_sizes,
    const int* tree_offsets,
    const int n_trees);

  struct two_track_evaluator_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      HostBuffers&,
      const Allen::Context& context) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
  };

} // namespace two_track_evaluator
