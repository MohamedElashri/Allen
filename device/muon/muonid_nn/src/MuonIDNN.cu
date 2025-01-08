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
#include "ArgumentOps.cuh"
#include "MuonDefinitions.cuh"
#include "MuonIDNN.cuh"
#include <cmath>

INSTANTIATE_ALGORITHM(muonid_nn::muonid_nn_t)

namespace muonid_nn {
  __constant__ float dev_weights[312];
  __constant__ float dev_biases[25];
} // namespace muonid_nn
void muonid_nn::muonid_nn_t::update(const Constants& constants) const
{
  Allen::memcpyToSymbol(dev_weights, constants.host_muonid_mva_weights, 312 * sizeof(float));
  Allen::memcpyToSymbol(dev_biases, constants.host_muonid_mva_biases, 25 * sizeof(float));
}
void muonid_nn::muonid_nn_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_muonid_evaluation_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
}

void muonid_nn::muonid_nn_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_muonid_evaluation_t>(arguments, 0, context);
  global_function(muonid_nn)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments,
    constants.dev_muonid_mva_layer_sizes,
    constants.dev_muonid_mva_n_layers,
    constants.dev_muonid_mva_monotone_constraints,
    constants.dev_muonid_mva_lambda);
}

__global__ void muonid_nn::muonid_nn(
  muonid_nn::Parameters parameters,
  const int* layer_sizes,
  const int n_layers,
  const float* monotone_constraints,
  const float lambda)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  // two buffers to do the network forward propagation
  float buf[64]; // assume width upper bound of 32
  constexpr int input_size = Muon::Constants::n_muon_id_features;
  const auto long_tracks = parameters.dev_long_tracks_view->container(event_number);
  for (unsigned track_idx = threadIdx.x; track_idx < long_tracks.size(); track_idx += blockDim.x) {
    float response = 0;
    if (parameters.dev_is_muon[long_tracks.offset() + track_idx]) {
      const float* muon_features_track =
        parameters.dev_muonid_features + input_size * (long_tracks.offset() + track_idx);

      response = propagation(
        input_size,
        layer_sizes,
        muon_features_track,
        monotone_constraints,
        lambda,
        dev_weights,
        dev_biases,
        n_layers,
        buf);
      const auto scifi_idx_with_offset = long_tracks.offset() + track_idx;
      parameters.dev_muonid_evaluation[scifi_idx_with_offset] = response;
    }
  }
}
