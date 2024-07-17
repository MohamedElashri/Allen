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
#include "ElectronIDNN.cuh"

INSTANTIATE_ALGORITHM(electronid_nn::electronid_nn_t)

void electronid_nn::electronid_nn_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_electronid_evaluation_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
}

void electronid_nn::electronid_nn_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_electronid_evaluation_t>(arguments, 0, context);
  global_function(electronid_nn)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments,
    constants.dev_electronid_mva_weights,
    constants.dev_electronid_mva_biases,
    constants.dev_electronid_mva_layer_sizes,
    constants.dev_electronid_mva_n_layers,
    constants.dev_electronid_mva_monotone_constraints,
    constants.dev_electronid_mva_lambda);
}

__global__ void electronid_nn::electronid_nn(
  electronid_nn::Parameters parameters,
  const float* weights,
  const float* biases,
  const int* layer_sizes,
  const int n_layers,
  const float* monotone_constraints,
  const float lambda)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  // two buffers to do the network forward propagation
  float buf[64]; // assume width upper bound of 32
  constexpr int input_size = 7;
  const auto long_tracks = parameters.dev_long_tracks_view->container(event_number);
  for (unsigned track_idx = threadIdx.x; track_idx < long_tracks.size(); track_idx += blockDim.x) {
    const auto scifi_idx_with_offset = long_tracks.offset() + track_idx;
    bool inAcc = parameters.dev_track_inEcalAcc[long_tracks.offset() + track_idx];
    bool preCut =
      parameters.dev_track_Eop[long_tracks.offset() + track_idx] > 0.7f; // hardcoded Eop3x3 cut to lower timing
    if (inAcc && preCut) {
      const float* electron_features_track =
        parameters.dev_electronid_features + input_size * (long_tracks.offset() + track_idx);
      float response = propagation(
        input_size, layer_sizes, electron_features_track, monotone_constraints, lambda, weights, biases, n_layers, buf);

      parameters.dev_electronid_evaluation[scifi_idx_with_offset] = response;
    }
  }
}
