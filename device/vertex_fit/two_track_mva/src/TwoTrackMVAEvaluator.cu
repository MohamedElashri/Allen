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
#include "TwoTrackMVAEvaluator.cuh"
#include <cmath>

INSTANTIATE_ALGORITHM(two_track_mva_evaluator::two_track_mva_evaluator_t)

namespace {
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
} // namespace

void two_track_mva_evaluator::two_track_mva_evaluator_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_two_track_mva_evaluation_t>(arguments, first<host_number_of_svs_t>(arguments));
}

void two_track_mva_evaluator::two_track_mva_evaluator_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{

  global_function(two_track_mva_evaluator)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments,
    constants.dev_two_track_mva_weights,
    constants.dev_two_track_mva_biases,
    constants.dev_two_track_mva_layer_sizes,
    constants.dev_two_track_mva_n_layers,
    constants.dev_two_track_mva_monotone_constraints,
    constants.dev_two_track_mva_lambda);
}

__global__ void two_track_mva_evaluator::two_track_mva_evaluator(
  two_track_mva_evaluator::Parameters parameters,
  const float* weights,
  const float* biases,
  const int* layer_sizes,
  const int n_layers,
  const float* monotone_constraints,
  const float lambda)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned sv_offset = parameters.dev_sv_offsets[event_number];
  const unsigned n_svs_in_evt = parameters.dev_sv_offsets[event_number + 1] - sv_offset;

  // two buffers to do the network forward propagation
  float buf1[32]; // assume width upper bound of 32
  float buf2[32];
  constexpr int input_size = 4;
  float vtx_data[input_size];

  for (unsigned sv_in_evt_idx = threadIdx.x; sv_in_evt_idx < n_svs_in_evt; sv_in_evt_idx += blockDim.x) {
    VertexFit::TrackMVAVertex vertex = parameters.dev_svs[sv_offset + sv_in_evt_idx];
    // fill input data
    // keep separate for the skip connection later
    vtx_data[0] = logf(vertex.fdchi2);
    vtx_data[1] = vertex.sumpt / 1000;
    vtx_data[2] = max(vertex.chi2, 1e-10f);
    vtx_data[3] = logf(vertex.minipchi2);
    // copy into buffer for forward pass through
    // main network
    for (int i = 0; i < input_size; ++i) {
      buf1[i] = vtx_data[i];
    }

    // preparation for forward pass
    const float* weight_ptr = weights;
    const float* bias_ptr = biases;
    float* input = buf1;
    float* output = buf2;

    // forward pass itself
    for (int layer_idx = 1; layer_idx < n_layers; ++layer_idx) {
      int n_inputs = layer_sizes[layer_idx - 1];
      int n_outputs = layer_sizes[layer_idx];
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

    float response = output[0] + lambda * dot(vtx_data, monotone_constraints, input_size);
    response = sigmoid(response);

    auto sv_idx = sv_in_evt_idx + sv_offset;
    parameters.dev_two_track_mva_evaluation[sv_idx] = response;
  }
}
