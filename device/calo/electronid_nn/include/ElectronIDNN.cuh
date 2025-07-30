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
#include "VertexDefinitions.cuh"
#include "MuonDefinitions.cuh"
#include "ParticleTypes.cuh"
#include "MultiLayerFCNN.cuh"

namespace electronid_nn {

  using NeuralNetworkType = Allen::MVAModels::MultiLayerFCNN<6, 12, 12, 12, 12, 1>;

  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;

    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_long_tracks_view_t, Allen::Views::Physics::MultiEventLongTracks) dev_long_tracks_view;

    DEVICE_INPUT(dev_track_inEcalAcc_t, bool) dev_track_inEcalAcc;

    DEVICE_INPUT(dev_track_Eop_t, float) dev_track_Eop;
    DEVICE_INPUT(dev_track_Eop3x3_t, float) dev_track_Eop3x3;
    DEVICE_INPUT(dev_delta_barycenter_t, float) dev_delta_barycenter;
    DEVICE_INPUT(dev_region_t, int) dev_region;
    DEVICE_INPUT(dev_dispersion_x_t, float) dev_dispersion_x;
    DEVICE_INPUT(dev_dispersion_y_t, float) dev_dispersion_y;
    DEVICE_INPUT(dev_dispersion_xy_t, float) dev_dispersion_xy;

    DEVICE_OUTPUT(dev_electronid_evaluation_t, float) dev_electronid_evaluation;
    DEVICE_OUTPUT(dev_is_electron_nn_t, bool) dev_is_electron_nn;
  };

  __global__ void electronid_nn(Parameters, const NeuralNetworkType::DeviceType*);

  struct electronid_nn_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;
    void update(const Constants& constants) const;
    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {32, 1, 1}, "block dimension"};
    NeuralNetworkType electron_id_nn {"electron_id_nn", "/CaloPID/electron_mva_AllenApr2025.json"};
  };

} // namespace electronid_nn
