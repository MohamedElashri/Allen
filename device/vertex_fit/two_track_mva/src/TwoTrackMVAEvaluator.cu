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
namespace two_track_mva_evaluator {
  __constant__ float dev_weights[NeuralNetworkType::HostType::n_weights];
  __constant__ float dev_biases[NeuralNetworkType::HostType::n_biases];
} // namespace two_track_mva_evaluator

void two_track_mva_evaluator::two_track_mva_evaluator_t::update(const Constants&) const
{
  Allen::memcpyToSymbol(
    dev_weights, two_track_mva_nn.get_weights(), NeuralNetworkType::HostType::n_weights * sizeof(float));
  Allen::memcpyToSymbol(
    dev_biases, two_track_mva_nn.get_biases(), NeuralNetworkType::HostType::n_biases * sizeof(float));
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
  const Constants&,
  const Allen::Context& context) const
{

  global_function(two_track_mva_evaluator)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments, two_track_mva_nn.getDevicePointer());
}

__global__ void two_track_mva_evaluator::two_track_mva_evaluator(
  two_track_mva_evaluator::Parameters parameters,
  const NeuralNetworkType::DeviceType* two_track_nn)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned sv_offset = parameters.dev_sv_offsets[event_number];
  const unsigned n_svs_in_evt = parameters.dev_sv_offsets[event_number + 1] - sv_offset;

  // two buffers to do the network forward propagation
  float buf[64];
  constexpr int input_size = NeuralNetworkType::DeviceType::n_features;
  float vtx_data[input_size];

  for (unsigned sv_in_evt_idx = threadIdx.x; sv_in_evt_idx < n_svs_in_evt; sv_in_evt_idx += blockDim.x) {
    VertexFit::TrackMVAVertex vertex = parameters.dev_svs[sv_offset + sv_in_evt_idx];

    // fill input data
    // keep separate for the skip connection later
    vtx_data[0] = logf(vertex.fdchi2);
    vtx_data[1] = vertex.sumpt / 1000;
    vtx_data[2] = max(vertex.chi2, 1e-10f);
    vtx_data[3] = logf(vertex.minipchi2);

    float responce = two_track_nn->propagation(vtx_data, dev_weights, dev_biases, buf);

    auto sv_idx = sv_in_evt_idx + sv_offset;
    parameters.dev_two_track_mva_evaluation[sv_idx] = responce;
  }
}
