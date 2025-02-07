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
  __constant__ float dev_weights[NeuralNetworkType::HostType::n_weights];
  __constant__ float dev_biases[NeuralNetworkType::HostType::n_biases];
} // namespace muonid_nn
void muonid_nn::muonid_nn_t::update(const Constants&) const
{
  Allen::memcpyToSymbol(dev_weights, muon_id_nn.get_weights(), NeuralNetworkType::HostType::n_weights * sizeof(float));
  Allen::memcpyToSymbol(dev_biases, muon_id_nn.get_biases(), NeuralNetworkType::HostType::n_biases * sizeof(float));
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
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_muonid_evaluation_t>(arguments, 0, context);
  global_function(muonid_nn)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments, muon_id_nn.getDevicePointer());
}

__global__ void muonid_nn::muonid_nn(
  muonid_nn::Parameters parameters,
  const NeuralNetworkType::DeviceType* muon_id_nn_evaluator)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];

  const float* min_rescales = muon_id_nn_evaluator->get_min_rescales();
  const float* max_rescales = muon_id_nn_evaluator->get_max_rescales();

  // two buffers to do the network forward propagation
  float buf[64]; // assume width upper bound of 32
  constexpr int input_size = Muon::Constants::n_muon_id_features;
  const auto long_tracks = parameters.dev_long_tracks_view->container(event_number);
  for (unsigned track_idx = threadIdx.x; track_idx < long_tracks.size(); track_idx += blockDim.x) {
    float response = 0;
    if (parameters.dev_is_muon[long_tracks.offset() + track_idx]) {
      const auto scifi_idx_with_offset = long_tracks.offset() + track_idx;

      const auto track = long_tracks.track(track_idx);

      using segment = Allen::Views::Physics::Track::segment;
      const auto muon_segment = track.track_segment<segment::muon>();
      MuonTrack muon_stub;
      applyWeightedFit<const Allen::Views::Muon::Consolidated::Track>(muon_stub, muon_segment, true, 1.f);
      applyWeightedFit<const Allen::Views::Muon::Consolidated::Track>(muon_stub, muon_segment, false, 1.f);

      const auto& scifi_state = parameters.dev_scifi_states[scifi_idx_with_offset];

      const float extrapol_x0_scifi = scifi_state.x() + scifi_state.tx() * (muon_segment.hit(0).z() - scifi_state.z());
      const float extrapol_y0_scifi = scifi_state.y() + scifi_state.ty() * (muon_segment.hit(0).z() - scifi_state.z());

      const float extrapol_x1_scifi = scifi_state.x() + scifi_state.tx() * (muon_segment.hit(1).z() - scifi_state.z());
      const float extrapol_y1_scifi = scifi_state.y() + scifi_state.ty() * (muon_segment.hit(1).z() - scifi_state.z());

      const float extrapol_x0 =
        Allen::MVAModels::square((extrapol_x0_scifi - muon_segment.hit(0).x()) / muon_segment.hit(0).dx());
      const float extrapol_x1 =
        Allen::MVAModels::square((extrapol_x1_scifi - muon_segment.hit(1).x()) / muon_segment.hit(1).dx());
      const float extrapol_y0 =
        Allen::MVAModels::square((extrapol_y0_scifi - muon_segment.hit(0).y()) / muon_segment.hit(0).dy());
      const float extrapol_y1 =
        Allen::MVAModels::square((extrapol_y1_scifi - muon_segment.hit(1).y()) / muon_segment.hit(1).dy());

      float logdx = Allen::MVAModels::log_feature(muon_stub.tx() - scifi_state.tx());
      float logdy = Allen::MVAModels::log_feature(muon_stub.ty() - scifi_state.ty());

      float muon_features_track[input_size];
      muon_features_track[0] = parameters.dev_chi2_muon[scifi_idx_with_offset];
      muon_features_track[1] = parameters.dev_chi2uncorr_muon[scifi_idx_with_offset];
      muon_features_track[2] = muon_segment.hit(1).time();
      muon_features_track[3] = muon_segment.hit(1).delta_time();
      muon_features_track[4] = muon_segment.hit(0).uncrossed();
      muon_features_track[5] = muon_segment.hit(1).uncrossed();
      muon_features_track[6] = logdx;
      muon_features_track[7] = logdy;
      muon_features_track[8] = Allen::MVAModels::log_feature(extrapol_x0);
      muon_features_track[9] = Allen::MVAModels::log_feature(extrapol_x1);
      muon_features_track[10] = Allen::MVAModels::log_feature(extrapol_y0);
      muon_features_track[11] = Allen::MVAModels::log_feature(extrapol_y1);

      for (unsigned i = 0; i < input_size; i++) {
        muon_features_track[i] = Allen::MVAModels::rescale(muon_features_track[i], i, min_rescales, max_rescales);
      }

      response = muon_id_nn_evaluator->propagation(muon_features_track, dev_weights, dev_biases, buf);

      parameters.dev_muonid_evaluation[scifi_idx_with_offset] = response;
    }
  }
}
