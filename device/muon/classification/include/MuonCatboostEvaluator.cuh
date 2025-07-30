/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#pragma once

#include "AlgorithmTypes.cuh"
#include "MuonDefinitions.cuh"
#include "CatboostDesTree.cuh"

namespace muon_catboost_evaluator {
  using NeuralNetworkType = Allen::MVAModels::CatboostDT;
  struct Parameters {
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, unsigned) host_number_of_reconstructed_scifi_tracks;
    DEVICE_INPUT(dev_muon_catboost_features_t, float) dev_muon_catboost_features;
    DEVICE_OUTPUT(dev_muon_catboost_output_t, float) dev_muon_catboost_output;
  };

  __global__ void muon_catboost_evaluator(Parameters, const NeuralNetworkType::DeviceType*);

  struct muon_catboost_evaluator_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const Allen::Context& context) const;

  private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {32, 1, 1}, "block dimensions"};

    NeuralNetworkType caloboost_muon {"caloboost_muon", "/allen_muon_catboost_model.json"};
  };
} // namespace muon_catboost_evaluator