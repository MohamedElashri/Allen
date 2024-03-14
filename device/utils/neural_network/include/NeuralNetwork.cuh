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

#include "BackendCommon.h"
#include "NeuralNetworkDefinition.cuh"

namespace Allen::NeuralNetwork {
  namespace ActivateFunction {
    // rectified linear unit
    __device__ inline float relu(const float x) { return x > 0 ? x : 0; }
    // sigmoid
    __device__ inline float sigmoid(const float x) { return __fdividef(1.0f, 1.0f + __expf(-x)); }
  } // namespace ActivateFunction

  template<typename ModelType>
  __device__ inline float evaluate(ModelType const* model, float* input)
  {
// Data preprocessing
#if (defined(TARGET_DEVICE_CUDA) && defined(__CUDACC__))
#pragma unroll
#endif
    for (unsigned i = 0; i < ModelType::nInput; i++) {
      input[i] = __fdividef(input[i] - model->mean[i], model->std[i]);
    }
    float h1[ModelType::nNode] = {0.f};

// First layer
#if (defined(TARGET_DEVICE_CUDA) && defined(__CUDACC__))
#pragma unroll
#endif
    for (unsigned i = 0; i < ModelType::nNode; i++) {
#if (defined(TARGET_DEVICE_CUDA) && defined(__CUDACC__))
#pragma unroll
#endif
      for (unsigned j = 0; j < ModelType::nInput; j++) {
        h1[i] += input[j] * model->weights1[i][j];
      }
      h1[i] = ActivateFunction::relu(h1[i] + model->bias1[i]);
    }

    // Output layer
    float output = 0.f;
#if (defined(TARGET_DEVICE_CUDA) && defined(__CUDACC__))
#pragma unroll
#endif
    for (unsigned i = 0; i < ModelType::nNode; i++) {
      output += h1[i] * model->weights2[i];
    }

    output = ActivateFunction::sigmoid(output + model->bias2);

    return output;
  }

} // namespace Allen::NeuralNetwork
