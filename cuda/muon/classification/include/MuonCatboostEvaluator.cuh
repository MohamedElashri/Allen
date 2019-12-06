#pragma once

#include "GpuAlgorithm.cuh"
#include "MuonDefinitions.cuh"
#include "ArgumentsMuon.cuh"

__global__ void muon_catboost_evaluator(
  const float* dev_muon_catboost_features,
  float* dev_muon_catboost_output,
  const float* dev_muon_catboost_leaf_values,
  const int* dev_muon_catboost_leaf_offsets,
  const float* dev_muon_catbost_split_borders,
  const int* dev_muon_catboost_split_features,
  const int* dev_muon_catboost_tree_sizes,
  const int* dev_muon_catboost_tree_offsets,
  const int n_trees);

struct muon_catboost_evaluator_t : public GpuAlgorithm {
  constexpr static auto name {"muon_catboost_evaluator_t"};
  decltype(gpu_function(muon_catboost_evaluator)) function {muon_catboost_evaluator};
  using Arguments = std::tuple<dev_muon_catboost_features, dev_muon_catboost_output, dev_is_muon>;

  void set_arguments_size(
    ArgumentRefManager<Arguments> arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const;

  void operator()(
    const ArgumentRefManager<Arguments>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const;
};
