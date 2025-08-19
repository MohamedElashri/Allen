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
#include "States.cuh"
#include "VeloConsolidated.cuh"

namespace pvinference {

  /**
   * @brief Parameters for PVinference algorithm
   * @details Defines input/output arguments for the PVFinder neural network algorithm
   */
  struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    MASK_INPUT(dev_event_list_t) dev_event_list;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_velo_kalman_beamline_states_t, Allen::Views::Physics::KalmanStates) dev_velo_kalman_beamline_states;
    DEVICE_OUTPUT(dev_output_kde_t, float) dev_output_kde;
    DEVICE_OUTPUT(dev_fc_workspace_t, float) dev_fc_workspace;
    DEVICE_OUTPUT(dev_unet_workspace_t, float) dev_unet_workspace;
    DEVICE_OUTPUT(dev_interval_histograms_t, float) dev_interval_histograms;
    DEVICE_OUTPUT(dev_fc_weights_t, float) dev_fc_weights;
    DEVICE_OUTPUT(dev_fc_biases_t, float) dev_fc_biases;
    DEVICE_OUTPUT(dev_unet_weights_t, float) dev_unet_weights;
    DEVICE_OUTPUT(dev_unet_biases_t, float) dev_unet_biases;
  };

  /**
   * @brief PVinference neural network inference algorithm
   * @details Implements complete PVFinder using FC + U-Net hybrid neural network
   *          for primary vertex finding in Allen framework. This is the production
   *          implementation ported from the standalone CUDA version.
   * 
   * Architecture:
   * - 6 FC layers (9→20→20→20→20→20→800) for feature extraction
   * - U-Net CNN for spatial processing (8 latent channels, 64 CNN channels)
   * - 40 intervals per event, 100 output KDE bins
   * - Binary weight loading from pvfinder_weights.bin
   */
  struct PVinference_t : public DeviceAlgorithm, Parameters {
    
    /**
     * @brief Set arguments size based on input parameters
     * @param arguments Algorithm arguments reference
     * @param runtime_options Runtime configuration options
     * @param constants Algorithm constants
     */
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;

    /**
     * @brief Main algorithm operator - executes PVFinder inference
     * @param arguments Algorithm arguments reference  
     * @param runtime_options Runtime configuration options
     * @param constants Algorithm constants
     * @param context Allen execution context
     */
    void operator()(
      const ArgumentReferences<Parameters>& arguments,
      const RuntimeOptions&,
      const Constants& constants,
      const Allen::Context& context) const;

    /**
     * @brief Update algorithm constants (load neural network weights)
     * @param constants Algorithm constants to update
     */
    void update(const Constants& constants) const;
    
  private:
    /**
     * @brief Load binary weights from pvfinder_weights.bin
     * @return true if weights loaded successfully
     */
    bool load_binary_weights() const;
    
    /**
     * @brief Transfer FC weights from host to device global memory
     * @param arguments Algorithm arguments reference
     * @param context Allen execution context
     */
    void transfer_fc_weights_to_device(
      const ArgumentReferences<Parameters>& arguments,
      const Allen::Context& context) const;

  };

} // namespace pvinference

// CUDA kernel declarations
__global__ void pvinference_kernel(
  pvinference::Parameters parameters);

// Neural network architecture constants
namespace PVinference {
  
  // FC network architecture (9->20->20->20->20->20->800)  
  constexpr unsigned FC_LAYERS = 6;
  constexpr unsigned FC_LAYER_SIZES[] = {9, 20, 20, 20, 20, 20, 800};
  constexpr unsigned FC_TOTAL_WEIGHTS = 9*20 + 20*20 + 20*20 + 20*20 + 20*20 + 20*800;
  constexpr unsigned FC_TOTAL_BIASES = 20 + 20 + 20 + 20 + 20 + 800;
  
  // U-Net architecture constants
  constexpr unsigned UNET_INPUT_CHANNELS = 8;
  constexpr unsigned UNET_CNN_CHANNELS = 64;
  constexpr unsigned UNET_INPUT_SIZE = 800;
  constexpr unsigned UNET_OUTPUT_SIZE = 100;
  
  // Processing constants
  constexpr unsigned N_INTERVALS = 40;
  constexpr unsigned KDE_BINS = 100;
  constexpr unsigned MAX_TRACKS_PER_EVENT = 1000;
  constexpr unsigned TRACK_FEATURES = 9;
  
  // Memory layout constants
  constexpr float Z_MIN = -100.0f;
  constexpr float Z_MAX = 300.0f;
  constexpr float INTERVAL_WIDTH = (Z_MAX - Z_MIN) / N_INTERVALS;
  
  // Phase 2: Input normalization in constant memory (small arrays)
  extern __constant__ float dev_input_mean[TRACK_FEATURES];
  extern __constant__ float dev_input_std[TRACK_FEATURES];
  
  // Phase 2: Only small arrays in constant memory to stay within 64KB limit
  constexpr unsigned FC_WEIGHT_COUNT = 9*20 + 20*20 + 20*20 + 20*20 + 20*20 + 20*800;
  constexpr unsigned FC_BIAS_COUNT = 20 + 20 + 20 + 20 + 20 + 800;
  // FC weights moved to global memory to avoid 64KB constant memory limit
  
  // Phase 2: Workspace memory sizes for fixed allocation
  constexpr unsigned WARP_SIZE = 32;
  constexpr unsigned FC_WORKSPACE_SIZE = WARP_SIZE * 20 * FC_LAYERS; // Per-warp FC processing
  constexpr unsigned UNET_WORKSPACE_SIZE = 64 * 100; // U-Net intermediate tensors per event
  constexpr unsigned INTERVAL_HISTOGRAM_SIZE = N_INTERVALS * KDE_BINS; // 40 x 100 per event
  
  // Phase 2: Estimated U-Net weight counts (to be refined in Phase 5)
  constexpr unsigned UNET_WEIGHT_COUNT = 50000; // Placeholder estimate
  constexpr unsigned UNET_BIAS_COUNT = 1000;    // Placeholder estimate

} // namespace PVinference
