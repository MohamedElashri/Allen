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
#include "NNPropagation.cuh"
#include "TwoTrackMVAEvaluator.cuh"
#include <cmath>

INSTANTIATE_ALGORITHM(two_track_mva_evaluator::two_track_mva_evaluator_t)
namespace two_track_mva_evaluator {
  __constant__ float dev_weights[500];
  __constant__ float dev_biases[41];
} // namespace two_track_mva_evaluator
void two_track_mva_evaluator::two_track_mva_evaluator_t::update(const Constants& constants) const
{
  Allen::memcpyToSymbol(dev_weights, constants.host_two_track_mva_weights, 500 * sizeof(float));
  Allen::memcpyToSymbol(dev_biases, constants.host_two_track_mva_biases, 41 * sizeof(float));
}

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
    constants.dev_two_track_mva_layer_sizes,
    constants.dev_two_track_mva_n_layers,
    constants.dev_two_track_mva_monotone_constraints,
    constants.dev_two_track_mva_lambda);
}

__global__ void two_track_mva_evaluator::two_track_mva_evaluator(
  two_track_mva_evaluator::Parameters parameters,
  const int* layer_sizes,
  const int n_layers,
  const float* monotone_constraints,
  const float lambda)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned sv_offset = parameters.dev_sv_offsets[event_number];
  const unsigned n_svs_in_evt = parameters.dev_sv_offsets[event_number + 1] - sv_offset;

  // two buffers to do the network forward propagation
  float buf[64];
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
    float response = propagation(
      input_size, layer_sizes, vtx_data, monotone_constraints, lambda, dev_weights, dev_biases, n_layers, buf);

    auto sv_idx = sv_in_evt_idx + sv_offset;
    parameters.dev_two_track_mva_evaluation[sv_idx] = response;
  }
}
