#include "Constants.cuh"
#include "ClusteringCommon.h"
#include "UTDefinitions.cuh"
#include "UTMagnetToolDefinitions.h"
#include "VeloDefinitions.cuh"
#include "ClusteringDefinitions.cuh"
#include "KalmanParametrizations.cuh"
#include "LookingForwardConstants.cuh"
#include "MuonDefinitions.cuh"
#include "MuonGeometry.cuh"
#include "MuonTables.cuh"

void Constants::reserve_constants()
{
  cudaCheck(cudaMalloc((void**) &dev_inv_clus_res, host_inv_clus_res.size() * sizeof(float)));
  cudaCheck(cudaMalloc((void**) &dev_kalman_params, sizeof(ParKalmanFilter::KalmanParametrizations)));
  cudaCheck(cudaMalloc((void**) &dev_looking_forward_constants, sizeof(LookingForward::Constants)));
  cudaCheck(cudaMalloc((void**) &dev_muon_foi, sizeof(Muon::Constants::FieldOfInterest)));
  cudaCheck(cudaMalloc((void**) &dev_muon_momentum_cuts, 3 * sizeof(float)));
}

void Constants::initialize_constants(
  const std::vector<float>& muon_field_of_interest_params,
  const std::string& folder_params_kalman)
{
  // SciFi constants
  host_inv_clus_res = {1 / 0.05, 1 / 0.08, 1 / 0.11, 1 / 0.14, 1 / 0.17, 1 / 0.20, 1 / 0.23, 1 / 0.26, 1 / 0.29};
  cudaCheck(
    cudaMemcpy(dev_inv_clus_res, &host_inv_clus_res, host_inv_clus_res.size() * sizeof(float), cudaMemcpyHostToDevice));

  host_looking_forward_constants = new LookingForward::Constants{};

  // Kalman filter constants.
  ParKalmanFilter::KalmanParametrizations host_kalman_params;
  host_kalman_params.SetParameters(folder_params_kalman, ParKalmanFilter::Polarity::Down);
  cudaCheck(cudaMemcpy(
    dev_kalman_params, &host_kalman_params, sizeof(ParKalmanFilter::KalmanParametrizations), cudaMemcpyHostToDevice));

  cudaCheck(cudaMemcpy(
    dev_looking_forward_constants,
    host_looking_forward_constants,
    sizeof(LookingForward::Constants),
    cudaMemcpyHostToDevice))

    // Muon constants
    Muon::Constants::FieldOfInterest host_muon_foi;
  const float* foi_iterator = muon_field_of_interest_params.data();
  for (uint i_station = 0; i_station < Muon::Constants::n_stations; i_station++) {
    std::copy_n(foi_iterator, Muon::Constants::n_regions, host_muon_foi.param_a_x[i_station]);
    foi_iterator += Muon::Constants::n_regions; // * sizeof(float);
    std::copy_n(foi_iterator, Muon::Constants::n_regions, host_muon_foi.param_a_y[i_station]);
    foi_iterator += Muon::Constants::n_regions; // * sizeof(float);
    std::copy_n(foi_iterator, Muon::Constants::n_regions, host_muon_foi.param_b_x[i_station]);
    foi_iterator += Muon::Constants::n_regions; // * sizeof(float);
    std::copy_n(foi_iterator, Muon::Constants::n_regions, host_muon_foi.param_b_y[i_station]);
    foi_iterator += Muon::Constants::n_regions; // * sizeof(float);
    std::copy_n(foi_iterator, Muon::Constants::n_regions, host_muon_foi.param_c_x[i_station]);
    foi_iterator += Muon::Constants::n_regions; // * sizeof(float);
    std::copy_n(foi_iterator, Muon::Constants::n_regions, host_muon_foi.param_c_y[i_station]);
    foi_iterator += Muon::Constants::n_regions;
  }
  cudaCheck(
    cudaMemcpy(dev_muon_momentum_cuts, &Muon::Constants::momentum_cuts, 3 * sizeof(float), cudaMemcpyHostToDevice));
  cudaCheck(cudaMemcpy(dev_muon_foi, &host_muon_foi, sizeof(Muon::Constants::FieldOfInterest), cudaMemcpyHostToDevice));
}

void Constants::initialize_muon_catboost_model_constants(
  const int n_trees,
  const std::vector<int>& tree_depths,
  const std::vector<int>& tree_offsets,
  const std::vector<float>& leaf_values,
  const std::vector<int>& leaf_offsets,
  const std::vector<float>& split_borders,
  const std::vector<int>& split_features)
{
  muon_catboost_n_trees = n_trees;
  cudaCheck(cudaMalloc((void**) &dev_muon_catboost_split_features, split_features.size() * sizeof(int)));
  cudaCheck(cudaMalloc((void**) &dev_muon_catboost_split_borders, split_borders.size() * sizeof(float)));
  cudaCheck(cudaMalloc((void**) &dev_muon_catboost_leaf_values, leaf_values.size() * sizeof(float)));
  cudaCheck(cudaMalloc((void**) &dev_muon_catboost_tree_depths, tree_depths.size() * sizeof(int)));
  cudaCheck(cudaMalloc((void**) &dev_muon_catboost_tree_offsets, tree_offsets.size() * sizeof(int)));
  cudaCheck(cudaMalloc((void**) &dev_muon_catboost_leaf_offsets, leaf_offsets.size() * sizeof(int)));

  cudaCheck(cudaMemcpy(
    dev_muon_catboost_split_features,
    split_features.data(),
    split_features.size() * sizeof(int),
    cudaMemcpyHostToDevice));
  cudaCheck(cudaMemcpy(
    dev_muon_catboost_split_borders,
    split_borders.data(),
    split_borders.size() * sizeof(float),
    cudaMemcpyHostToDevice));
  cudaCheck(cudaMemcpy(
    dev_muon_catboost_leaf_values, leaf_values.data(), leaf_values.size() * sizeof(float), cudaMemcpyHostToDevice));
  cudaCheck(cudaMemcpy(
    dev_muon_catboost_tree_depths, tree_depths.data(), tree_depths.size() * sizeof(int), cudaMemcpyHostToDevice));
  cudaCheck(cudaMemcpy(
    dev_muon_catboost_tree_offsets, tree_offsets.data(), tree_offsets.size() * sizeof(int), cudaMemcpyHostToDevice));
  cudaCheck(cudaMemcpy(
    dev_muon_catboost_leaf_offsets, leaf_offsets.data(), leaf_offsets.size() * sizeof(int), cudaMemcpyHostToDevice));
}
