#pragma once

#include "DeviceAlgorithm.cuh"
#include "MuonDefinitions.cuh"

namespace muon_catboost_evaluator {
  struct Parameters {
    HOST_INPUT(host_number_of_reconstructed_scifi_tracks_t, uint);
    DEVICE_INPUT(dev_muon_catboost_features_t, float) dev_muon_catboost_features;
    DEVICE_OUTPUT(dev_muon_catboost_output_t, float) dev_muon_catboost_output;
    PROPERTY(blockdim_t, DeviceDimensions, "block_dim", "block dimensions", {32, 1, 1});
  };

  __global__ void muon_catboost_evaluator(
    Parameters,
    const float* dev_muon_catboost_leaf_values,
    const int* dev_muon_catboost_leaf_offsets,
    const float* dev_muon_catbost_split_borders,
    const int* dev_muon_catboost_split_features,
    const int* dev_muon_catboost_tree_sizes,
    const int* dev_muon_catboost_tree_offsets,
    const int n_trees);

  template<typename T, char... S>
  struct muon_catboost_evaluator_t : public DeviceAlgorithm, Parameters {
    constexpr static auto name = Name<S...>::s;
    decltype(global_function(muon_catboost_evaluator)) function {muon_catboost_evaluator};

    void set_arguments_size(
      ArgumentRefManager<T> arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      const HostBuffers& host_buffers) const
    {
      set_size<dev_muon_catboost_output_t>(arguments, value<host_number_of_reconstructed_scifi_tracks_t>(arguments));
    }

    void operator()(
      const ArgumentRefManager<T>& arguments,
      const RuntimeOptions& runtime_options,
      const Constants& constants,
      HostBuffers& host_buffers,
      cudaStream_t& cuda_stream,
      cudaEvent_t& cuda_generic_event) const
    {
      function(dim3(value<host_number_of_reconstructed_scifi_tracks_t>(arguments)), property<blockdim_t>(), cuda_stream)(
        Parameters {begin<dev_muon_catboost_features_t>(arguments), begin<dev_muon_catboost_output_t>(arguments)},
        constants.dev_muon_catboost_leaf_values,
        constants.dev_muon_catboost_leaf_offsets,
        constants.dev_muon_catboost_split_borders,
        constants.dev_muon_catboost_split_features,
        constants.dev_muon_catboost_tree_depths,
        constants.dev_muon_catboost_tree_offsets,
        constants.muon_catboost_n_trees);

      if (runtime_options.do_check) {
        cudaCheck(cudaMemcpyAsync(
          host_buffers.host_muon_catboost_output,
          begin<dev_muon_catboost_output_t>(arguments),
          size<dev_muon_catboost_output_t>(arguments),
          cudaMemcpyDeviceToHost,
          cuda_stream));
      }
    }

  private:
    Property<blockdim_t> m_blockdim {this};
  };
} // namespace muon_catboost_evaluator