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
#include "MultiLayerFCNN.cuh"
#include <cmath>

namespace two_track_mva_evaluator {

  using NeuralNetworkType = Allen::MVAModels::MultiLayerFCNN<4, 20, 20, 1>;

  struct Parameters {
    MASK_INPUT(dev_event_list_t) dev_event_list;
    HOST_INPUT(host_number_of_svs_t, unsigned) host_number_of_svs;
    DEVICE_INPUT(dev_consolidated_svs_t, VertexFit::TrackMVAVertex) dev_svs;
    DEVICE_INPUT(dev_sv_offsets_t, unsigned) dev_sv_offsets;
    DEVICE_OUTPUT(dev_two_track_mva_evaluation_t, float) dev_two_track_mva_evaluation;
  };

  __global__ void two_track_mva_evaluator(Parameters, const NeuralNetworkType::DeviceType*);

  struct two_track_mva_evaluator_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;
    void update(const Constants& constants) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {64, 1, 1}, "block dimension"};

    NeuralNetworkType two_track_mva_nn {"two_track_mva_nn", "/allen_two_track_mva_model_June22.json"};
  };

} // namespace two_track_mva_evaluator
