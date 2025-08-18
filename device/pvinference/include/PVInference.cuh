#pragma once

#include "AlgorithmTypes.cuh"
#include "States.cuh"
#include "VeloConsolidated.cuh"
#include "binary_weight_loader.h"

namespace PVInference {

// Algorithm constants - match UpperLimit standalone implementation
constexpr unsigned MAX_TRACKS_PER_EVENT = 2048;         // Match standalone maxTracks
constexpr unsigned FC_LAYERS = 6;
constexpr unsigned FC_HIDDEN_SIZE = 20;
constexpr unsigned FC_OUTPUT_SIZE = 800;                 // 8 latent channels x 100 bins
constexpr unsigned NUM_INTERVALS = 40;
constexpr unsigned HISTOGRAM_SIZE = 100;
constexpr unsigned LATENT_CHANNELS = 8;                  // U-Net input channels
constexpr unsigned UNET_CHANNELS = 64;                   // U-Net conv channels
constexpr float Z_MIN = -100.0f;
constexpr float Z_MAX = 300.0f;

// Input feature dimension (x, y, z, tx, ty, covariance diagonal)
constexpr unsigned INPUT_FEATURES = 9;

// U-Net layer dimensions
constexpr unsigned CONV1D_KERNEL_SIZE = 3;
constexpr unsigned TRANSPOSE_CONV_KERNEL_SIZE = 2;

struct Parameters {
    HOST_INPUT(host_number_of_events_t, unsigned) host_number_of_events;
    DEVICE_INPUT(dev_number_of_events_t, unsigned) dev_number_of_events;
    DEVICE_INPUT(dev_velo_tracks_view_t, Allen::Views::Velo::Consolidated::Tracks) dev_velo_tracks_view;
    DEVICE_INPUT(dev_velo_states_view_t, Allen::Views::Physics::KalmanStates) dev_velo_states_view;
    
    // Track processing tensors
    DEVICE_OUTPUT(dev_track_features_t, float) dev_track_features;          // max_tracks x 9 features
    DEVICE_OUTPUT(dev_track_masks_t, float) dev_track_masks;                // max_tracks validity masks
    DEVICE_OUTPUT(dev_interval_assignments_t, int) dev_interval_assignments; // track to interval mapping
    
    // FC layer intermediate outputs (6 layers: 9→20→20→20→20→20→800)
    DEVICE_OUTPUT(dev_fc_layer1_t, float) dev_fc_layer1;                   // max_tracks x 20
    DEVICE_OUTPUT(dev_fc_layer2_t, float) dev_fc_layer2;                   // max_tracks x 20
    DEVICE_OUTPUT(dev_fc_layer3_t, float) dev_fc_layer3;                   // max_tracks x 20
    DEVICE_OUTPUT(dev_fc_layer4_t, float) dev_fc_layer4;                   // max_tracks x 20
    DEVICE_OUTPUT(dev_fc_layer5_t, float) dev_fc_layer5;                   // max_tracks x 20
    DEVICE_OUTPUT(dev_fc_layer6_t, float) dev_fc_layer6;                   // max_tracks x 800 (8 x 100)
    
    // Interval processing tensors
    DEVICE_OUTPUT(dev_interval_kde_t, float) dev_interval_kde;              // 40 intervals x 8 channels x 100 bins
    DEVICE_OUTPUT(dev_aggregated_kde_t, float) dev_aggregated_kde;          // 8 channels x 100 bins per event
    
    // U-Net processing tensors
    DEVICE_OUTPUT(dev_unet_input_t, float) dev_unet_input;                 // 8 x 100 (latent input to U-Net)
    DEVICE_OUTPUT(dev_x1_t, float) dev_x1;                                 // 64 x 100 (after rcbn1)
    DEVICE_OUTPUT(dev_x2_t, float) dev_x2;                                 // 64 x 50 (after rcbn2 + pool)
    DEVICE_OUTPUT(dev_x3_t, float) dev_x3;                                 // 64 x 50 (after rcbn3 pre-pool)
    DEVICE_OUTPUT(dev_x3_pooled_t, float) dev_x3_pooled;                   // 64 x 25 (after rcbn3 + pool)
    DEVICE_OUTPUT(dev_x_up1_t, float) dev_x_up1;                          // 64 x 50 (after up1 transpose conv)
    DEVICE_OUTPUT(dev_x_up1_temp_t, float) dev_x_up1_temp;                // 64 x 50 (up1 conv1d temp)
    DEVICE_OUTPUT(dev_x_up2_t, float) dev_x_up2;                          // 64 x 100 (after up2 transpose conv)
    DEVICE_OUTPUT(dev_x_up2_temp_t, float) dev_x_up2_temp;                // 64 x 100 (up2 conv1d temp)
    DEVICE_OUTPUT(dev_x_combined1_t, float) dev_x_combined1;               // 128 x 50 (concat for up2)
    DEVICE_OUTPUT(dev_x_combined2_t, float) dev_x_combined2;               // 128 x 100 (concat for final)
    DEVICE_OUTPUT(dev_x_intermediate_t, float) dev_x_intermediate;          // 64 x 100 (out_intermediate)
    
    // Final PV histogram output (100 bins per event)
    DEVICE_OUTPUT(dev_pv_histogram_t, float) dev_pv_histogram;
    
    // Neural network weights on device
    DEVICE_OUTPUT(dev_fc_weights_t, float) dev_fc_weights;       // All FC layer weights
    DEVICE_OUTPUT(dev_fc_biases_t, float) dev_fc_biases;         // All FC layer biases
    DEVICE_OUTPUT(dev_unet_weights_t, float) dev_unet_weights;   // All U-Net weights
    DEVICE_OUTPUT(dev_unet_biases_t, float) dev_unet_biases;     // All U-Net biases
};

// Main kernel function
__global__ void pv_inference_kernel(Parameters parameters);

struct PVInference_t : public DeviceAlgorithm, Parameters {
    void set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const;
    void operator()(
        const ArgumentReferences<Parameters>& arguments,
        const RuntimeOptions&,
        const Constants&,
        const Allen::Context& context) const;

private:
    Allen::Property<dim3> m_block_dim {this, "block_dim", {256, 1, 1}, "block dimensions"};
    Allen::Property<unsigned> m_max_tracks_per_event {this, "max_tracks_per_event", MAX_TRACKS_PER_EVENT, "Maximum tracks to process per event"};
    Allen::Property<bool> m_enable_debug {this, "enable_debug", false, "Enable minimal debug output"};
    Allen::Property<float> m_z_min {this, "z_min", Z_MIN, "Minimum z coordinate for interval assignment"};
    Allen::Property<float> m_z_max {this, "z_max", Z_MAX, "Maximum z coordinate for interval assignment"};
};

// Device functions for track processing
__device__ void extract_track_features(
    const Allen::Views::Physics::KalmanState& state,
    float* features);

__device__ void assign_track_intervals(
    float z_poca,
    int& interval1,
    int& interval2,
    bool& has_second);

__device__ bool calculate_poca(
    const Allen::Views::Physics::KalmanState& state,
    float& poca_x,
    float& poca_y,
    float& poca_z);

// Neural network device functions
__device__ void fc_forward_pass(
    const float* input,
    float* output,
    const float* weights,
    const float* biases);

__device__ void softplus_activation(
    float* data,
    unsigned size);

// Weight loading functions
void load_fc_weights_to_device(
    float* dev_fc_weights,
    float* dev_fc_biases,
    const Allen::Context& context);

void load_unet_weights_to_device(
    float* dev_unet_weights,
    float* dev_unet_biases,
    const Allen::Context& context);

} // namespace PVInference
