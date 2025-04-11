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
#include "CaloConstants.cuh"
#include "ElectronIDNN.cuh"

INSTANTIATE_ALGORITHM(electronid_nn::electronid_nn_t)
namespace electronid_nn {
  __constant__ float dev_weights[NeuralNetworkType::HostType::n_weights];
  __constant__ float dev_biases[NeuralNetworkType::HostType::n_biases];
} // namespace electronid_nn
void electronid_nn::electronid_nn_t::update(const Constants&) const
{
  Allen::memcpyToSymbol(
    dev_weights, electron_id_nn.get_weights(), NeuralNetworkType::HostType::n_weights * sizeof(float));
  Allen::memcpyToSymbol(dev_biases, electron_id_nn.get_biases(), NeuralNetworkType::HostType::n_biases * sizeof(float));
}

void electronid_nn::electronid_nn_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_electronid_evaluation_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_is_electron_nn_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
}

void electronid_nn::electronid_nn_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_electronid_evaluation_t>(arguments, 0, context);
  global_function(electronid_nn)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments, electron_id_nn.getDevicePointer());
}

__global__ void electronid_nn::electronid_nn(
  electronid_nn::Parameters parameters,
  const NeuralNetworkType::DeviceType* electronid_nn_evaluator)
{

  const float* min_rescales = electronid_nn_evaluator->get_min_rescales();
  const float* max_rescales = electronid_nn_evaluator->get_max_rescales();

  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  // two buffers to do the network forward propagation
  float buf[64]; // assume width upper bound of 32
  constexpr int input_size = Calo::Constants::n_electron_id_features;
  const auto long_tracks = parameters.dev_long_tracks_view->container(event_number);
  for (unsigned track_idx = threadIdx.x; track_idx < long_tracks.size(); track_idx += blockDim.x) {
    const auto scifi_idx_with_offset = long_tracks.offset() + track_idx;
    if (
      parameters.dev_track_inEcalAcc[scifi_idx_with_offset] &&
      // Eop3x3 has no left tail
      parameters.dev_track_Eop3x3[scifi_idx_with_offset] > 0.4f &&
      // Eop has no right tail
      parameters.dev_track_Eop[scifi_idx_with_offset] < 2.f) {

      int region = parameters.dev_region[scifi_idx_with_offset];
      float region_s = Calo::Constants::region_size_0 + region * Calo::Constants::region_size_1 +
                       Calo::Constants::region_size_2 * region * region; // Get the region size from the region index:
      // 0 -> 121.2 mm
      // 1 -> 60.6 mm
      // 2 -> 40.4 mm
      float region_s2 = region_s * region_s;
      float logdb = Allen::MVAModels::log_feature(parameters.dev_delta_barycenter[scifi_idx_with_offset] / region_s2);
      float logdx = Allen::MVAModels::log_feature(parameters.dev_dispersion_x[scifi_idx_with_offset] / region_s2);
      float logdy = Allen::MVAModels::log_feature(parameters.dev_dispersion_y[scifi_idx_with_offset] / region_s2);
      float logdxy = Allen::MVAModels::log_feature(parameters.dev_dispersion_xy[scifi_idx_with_offset]);

      float electron_features_track[input_size];

      electron_features_track[0] = parameters.dev_track_Eop[scifi_idx_with_offset];
      electron_features_track[1] = parameters.dev_track_Eop3x3[scifi_idx_with_offset];
      electron_features_track[2] = logdb;
      electron_features_track[3] = logdx;
      electron_features_track[4] = logdy;
      electron_features_track[5] = logdxy;
      for (unsigned i = 0; i < input_size; i++) {
        electron_features_track[i] =
          Allen::MVAModels::rescale(electron_features_track[i], i, min_rescales, max_rescales);
      }

      float response = electronid_nn_evaluator->propagation(electron_features_track, dev_weights, dev_biases, buf);

      parameters.dev_electronid_evaluation[scifi_idx_with_offset] = response;
      parameters.dev_is_electron_nn[scifi_idx_with_offset] = response > 0.6f;
    }
    else {
      parameters.dev_electronid_evaluation[scifi_idx_with_offset] = 0;
      parameters.dev_is_electron_nn[scifi_idx_with_offset] = false;
    }
  }
}
