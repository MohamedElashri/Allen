#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"

namespace muon_catboost_evaluator {
  DEFINE_PARAMETERS(
    Parameters,
    (HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, uint), host_number_of_reconstructed_scifi_tracks),
    (DEVICE_INPUT(dev_muon_catboost_features_t, float), dev_muon_catboost_features),
    (DEVICE_OUTPUT(dev_muon_catboost_output_t, float), dev_muon_catboost_output),
    (PROPERTY(block_dim_t, "block_dim", "block dimensions", DeviceDimensions), block_dim))

  __global__ void muon_catboost_evaluator(
    Parameters,
    const float* dev_muon_catboost_leaf_values,
    const int* dev_muon_catboost_leaf_offsets,
    const float* dev_muon_catbost_split_borders,
    const int* dev_muon_catboost_split_features,
    const int* dev_muon_catboost_tree_sizes,
    const int* dev_muon_catboost_tree_offsets,
    const int n_trees);

  struct muon_catboost_evaluator_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(
      ArgumentReferences<Parameters> arguments,
      const RuntimeOptions&,
      const Constants&,
      const HostBuffers&) const;

    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t&) const;

  private:
    Property<block_dim_t> m_block_dim {this, {{32, 1, 1}}};
  };
} // namespace muon_catboost_evaluator