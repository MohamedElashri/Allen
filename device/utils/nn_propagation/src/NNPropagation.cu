/*****************************************************************************\
* (c) Copyright 2023 CERN for the benefit of the LHCb Collaboration           *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "COPYING".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "NNPropagation.cuh"

__device__ void groupsort2(float* x, int x_size)
{
  for (int i = 0; i < x_size; i += 2) {
    auto lhs = x[i];
    auto rhs = x[i + 1];
    auto ge = lhs >= rhs;
    x[i] = ge ? rhs : lhs;
    x[i + 1] = ge ? lhs : rhs;
  }
}

__device__ void multiply(float const* w, float const* x, int R, int C, float* out)
{
  // w * x = sum_j (w_ij*xj)
  for (int i = 0; i < R; ++i) {
    out[i] = 0;
    for (int j = 0; j < C; ++j) {
      out[i] += w[i * C + j] * x[j];
    }
  }
}

__device__ void add_in_place(float* a, float const* b, int size)
{
  for (int i = 0; i < size; ++i) {
    a[i] = a[i] + b[i];
  }
}

__device__ float dot(float const* a, float const* b, int size)
{
  float out = 0;
  for (int i = 0; i < size; ++i) {
    out += a[i] * b[i];
  }
  return out;
}

__device__ float sigmoid(float x) { return 1 / (1 + expf(-1 * x)); }

__device__ float propagation(
  const size_t input_size,
  const int* layer_sizes,
  const float* features_track,
  const float* monotone_constraints,
  const float lambda,
  const float* weights,
  const float* biases,
  const size_t n_layers,
  float* buf)
{
  float* buf1 = buf;
  float* buf2 = buf + 32;
  float response;
  // copy into buffer for forward pass through
  // main network
  for (size_t i = 0; i < input_size; ++i) {
    buf1[i] = features_track[i];
  }

  // preparation for forward pass
  const float* weight_ptr = weights;
  const float* bias_ptr = biases;
  float* input = buf1;
  float* output = buf2;

  // forward pass itself
  for (unsigned layer_idx = 1; layer_idx < n_layers; ++layer_idx) {
    unsigned n_inputs = layer_sizes[layer_idx - 1];
    unsigned n_outputs = layer_sizes[layer_idx];
    // W * x

    multiply(weight_ptr, input, n_outputs, n_inputs, output);
    // point to next layers weights
    weight_ptr += n_outputs * n_inputs;
    // W * x + b
    add_in_place(output, bias_ptr, n_outputs);
    // point to next layers biases
    bias_ptr += n_outputs;

    // activation (if not last layer)
    if (layer_idx != n_layers - 1) {
      groupsort2(output, n_outputs);
      // swap data pointers ( buf1 <-> buf2 )
      // for the next loop iteration
      float* tmp = input;
      input = output;
      output = tmp;
    }
  }
  response = output[0] + lambda * dot(features_track, monotone_constraints, input_size);
  return std::isfinite(response) ? sigmoid(response) : 0.f;
}
