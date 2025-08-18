#include "PVInference.cuh"
#include <cuda_runtime.h>

INSTANTIATE_ALGORITHM(PVInference::PVInference_t)

namespace PVInference {

// Set memory allocation sizes for all intermediate tensors
void PVInference_t::set_arguments_size(
    ArgumentReferences<Parameters> arguments, 
    const RuntimeOptions&, 
    const Constants&) const 
{
    const auto number_of_events = first<host_number_of_events_t>(arguments);
    const auto max_tracks = m_max_tracks_per_event;
    
    // Track processing tensors
    set_size<dev_track_features_t>(arguments, number_of_events * max_tracks * INPUT_FEATURES);
    set_size<dev_track_masks_t>(arguments, number_of_events * max_tracks);
    set_size<dev_interval_assignments_t>(arguments, number_of_events * max_tracks * 2); // up to 2 intervals per track
    
    // FC layer intermediate outputs (6 layers: 9→20→20→20→20→20→800)
    set_size<dev_fc_layer1_t>(arguments, number_of_events * max_tracks * FC_HIDDEN_SIZE);        // 20
    set_size<dev_fc_layer2_t>(arguments, number_of_events * max_tracks * FC_HIDDEN_SIZE);        // 20
    set_size<dev_fc_layer3_t>(arguments, number_of_events * max_tracks * FC_HIDDEN_SIZE);        // 20
    set_size<dev_fc_layer4_t>(arguments, number_of_events * max_tracks * FC_HIDDEN_SIZE);        // 20
    set_size<dev_fc_layer5_t>(arguments, number_of_events * max_tracks * FC_HIDDEN_SIZE);        // 20
    set_size<dev_fc_layer6_t>(arguments, number_of_events * max_tracks * FC_OUTPUT_SIZE);        // 800 (8 x 100)
    
    // Interval processing tensors
    set_size<dev_interval_kde_t>(arguments, number_of_events * NUM_INTERVALS * LATENT_CHANNELS * HISTOGRAM_SIZE); // 40 x 8 x 100
    set_size<dev_aggregated_kde_t>(arguments, number_of_events * LATENT_CHANNELS * HISTOGRAM_SIZE);               // 8 x 100
    
    // U-Net processing tensors
    set_size<dev_unet_input_t>(arguments, number_of_events * LATENT_CHANNELS * HISTOGRAM_SIZE);      // 8 x 100
    set_size<dev_x1_t>(arguments, number_of_events * UNET_CHANNELS * HISTOGRAM_SIZE);                // 64 x 100
    set_size<dev_x2_t>(arguments, number_of_events * UNET_CHANNELS * 50);                            // 64 x 50
    set_size<dev_x3_t>(arguments, number_of_events * UNET_CHANNELS * 50);                            // 64 x 50
    set_size<dev_x3_pooled_t>(arguments, number_of_events * UNET_CHANNELS * 25);                     // 64 x 25
    set_size<dev_x_up1_t>(arguments, number_of_events * UNET_CHANNELS * 50);                         // 64 x 50
    set_size<dev_x_up1_temp_t>(arguments, number_of_events * UNET_CHANNELS * 50);                    // 64 x 50
    set_size<dev_x_up2_t>(arguments, number_of_events * UNET_CHANNELS * HISTOGRAM_SIZE);             // 64 x 100
    set_size<dev_x_up2_temp_t>(arguments, number_of_events * UNET_CHANNELS * HISTOGRAM_SIZE);        // 64 x 100
    set_size<dev_x_combined1_t>(arguments, number_of_events * UNET_CHANNELS * 2 * 50);               // 128 x 50
    set_size<dev_x_combined2_t>(arguments, number_of_events * UNET_CHANNELS * 2 * HISTOGRAM_SIZE);   // 128 x 100
    set_size<dev_x_intermediate_t>(arguments, number_of_events * UNET_CHANNELS * HISTOGRAM_SIZE);     // 64 x 100
    
    // Final PV histogram output: 100 bins per event
    set_size<dev_pv_histogram_t>(arguments, number_of_events * HISTOGRAM_SIZE);
}

// Main algorithm operator
void PVInference_t::operator()(
    const ArgumentReferences<Parameters>& arguments,
    const RuntimeOptions&,
    const Constants&,
    const Allen::Context& context) const 
{
    // Initialize weights if not already done
    static bool weights_initialized = false;
    if (!weights_initialized) {
        if (!AllenWeightLoader::initialize()) {
            // Handle initialization failure - for now just return
            return;
        }
        weights_initialized = true;
    }
    
    // Launch main kernel
    const auto grid_size = dim3(first<host_number_of_events_t>(arguments));
    const auto block_size = m_block_dim;
    
    global_function(pv_inference_kernel)(grid_size, block_size, context)(arguments);
}

// CUDA kernels for PVFinder neural network inference

// FC layer forward pass kernel - adapted from UpperLimit
__device__ void fc_forward_layer(
    const float* input, 
    const float* weight, 
    const float* bias, 
    float* output,
    int input_size, 
    int output_size, 
    bool apply_leaky_relu = true) 
{
    const float leaky_alpha = 0.01f;
    
    for (int out_idx = 0; out_idx < output_size; ++out_idx) {
        float sum = bias[out_idx];
        
        // Matrix multiplication: output = input * weight + bias
        for (int in_idx = 0; in_idx < input_size; ++in_idx) {
            sum += input[in_idx] * weight[in_idx * output_size + out_idx];
        }
        
        // Apply LeakyReLU activation (Python: LeakyReLU(0.01))
        if (apply_leaky_relu) {
            output[out_idx] = (sum > 0.0f) ? sum : leaky_alpha * sum;
        } else {
            output[out_idx] = sum;
        }
    }
}

// Track mask generation kernel - adapted from UpperLimit  
__device__ bool generate_track_mask(const float* features) {
    // Check first feature (Python logic: x[:, 0, :] > -98)
    return features[0] > -98.0f;
}

// Softplus activation kernel - adapted from UpperLimit
__device__ float softplus_activation(float x) {
    // Numerically stable softplus implementation
    const float threshold = 20.0f;
    if (x > threshold) {
        return x;  // Approximation for large values
    } else {
        return logf(1.0f + expf(x));  // Exact for small values
    }
}

// Main PV inference kernel - one block per event
__global__ void pv_inference_kernel(Parameters parameters) {
    const unsigned event_id = blockIdx.x;
    const unsigned thread_id = threadIdx.x;
    const unsigned block_size = blockDim.x;
    
    // Get tracks for this event
    const auto velo_tracks = parameters.dev_velo_tracks_view[event_id];
    const auto velo_states = parameters.dev_velo_states_view[event_id];
    
    const unsigned num_tracks = velo_tracks.size();
    const unsigned max_tracks = min(num_tracks, MAX_TRACKS_PER_EVENT);
    
    // Shared memory for temporary computations
    __shared__ float s_aggregated_kde[LATENT_CHANNELS * HISTOGRAM_SIZE];
    __shared__ int s_valid_tracks[NUM_INTERVALS];
    
    // Initialize shared memory
    if (thread_id == 0) {
        for (int i = 0; i < LATENT_CHANNELS * HISTOGRAM_SIZE; ++i) {
            s_aggregated_kde[i] = 0.0f;
        }
        for (int i = 0; i < NUM_INTERVALS; ++i) {
            s_valid_tracks[i] = 0;
        }
    }
    __syncthreads();
    
    // Process tracks in parallel across threads
    for (unsigned track_idx = thread_id; track_idx < max_tracks; track_idx += block_size) {
        // Extract track features (9D: x, y, z, tx, ty, covariance diagonal)
        float features[INPUT_FEATURES];
        const auto& state = velo_states[track_idx];
        
        extract_track_features(state, features);
        
        // Generate track mask
        bool track_valid = generate_track_mask(features);
        if (!track_valid) continue;
        
        // Calculate POCA for interval assignment
        float poca_x, poca_y, poca_z;
        bool poca_valid = calculate_poca(state, poca_x, poca_y, poca_z);
        if (!poca_valid) continue;
        
        // Assign track to intervals (40 intervals from z=-100 to z=300)
        int interval1, interval2;
        bool has_second;
        assign_track_intervals(poca_z, interval1, interval2, has_second);
        
        // FC layer forward pass (6 layers: 9→20→20→20→20→20→800)
        float layer_outputs[6][FC_OUTPUT_SIZE];  // Max size is 800 for layer 6
        
        // Get weights from AllenWeightLoader (placeholder - will be implemented with actual weights)
        const float* fc_weights[6] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr};
        const float* fc_biases[6] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr};
        
        // Layer 1: 9 → 20
        fc_forward_layer(features, fc_weights[0], fc_biases[0], layer_outputs[0], INPUT_FEATURES, FC_HIDDEN_SIZE);
        
        // Layers 2-5: 20 → 20
        for (int layer = 1; layer < 5; ++layer) {
            fc_forward_layer(layer_outputs[layer-1], fc_weights[layer], fc_biases[layer], 
                           layer_outputs[layer], FC_HIDDEN_SIZE, FC_HIDDEN_SIZE);
        }
        
        // Layer 6: 20 → 800 (8 channels × 100 bins)
        fc_forward_layer(layer_outputs[4], fc_weights[5], fc_biases[5], 
                        layer_outputs[5], FC_HIDDEN_SIZE, FC_OUTPUT_SIZE, false);
        
        // Apply per-interval softplus + 0.001 scaling (matches Python behavior)
        for (int i = 0; i < FC_OUTPUT_SIZE; ++i) {
            float softplus_result = softplus_activation(layer_outputs[5][i]);
            layer_outputs[5][i] = softplus_result * 0.001f;
        }
        
        // Store track results in global memory for potential debugging
        const unsigned track_offset = event_id * MAX_TRACKS_PER_EVENT + track_idx;
        for (unsigned i = 0; i < FC_OUTPUT_SIZE; ++i) {
            parameters.dev_fc_layer6[track_offset * FC_OUTPUT_SIZE + i] = layer_outputs[5][i];
        }
        
        // Accumulate into shared memory for aggregation
        for (int ch = 0; ch < LATENT_CHANNELS; ++ch) {
            for (int bin = 0; bin < HISTOGRAM_SIZE; ++bin) {
                int fc_idx = ch * HISTOGRAM_SIZE + bin;
                atomicAdd(&s_aggregated_kde[fc_idx], layer_outputs[5][fc_idx]);
            }
        }
        
        // Update interval counts
        atomicAdd(&s_valid_tracks[interval1], 1);
        if (has_second) {
            atomicAdd(&s_valid_tracks[interval2], 1);
        }
    }
    
    __syncthreads();
    
    // Copy aggregated results to global memory (thread 0 only)
    if (thread_id == 0) {
        const unsigned event_offset = event_id * LATENT_CHANNELS * HISTOGRAM_SIZE;
        for (int i = 0; i < LATENT_CHANNELS * HISTOGRAM_SIZE; ++i) {
            parameters.dev_aggregated_kde[event_offset + i] = s_aggregated_kde[i];
        }
        
        // Initialize U-Net input with aggregated KDE (placeholder for Phase 3.2)
        for (int i = 0; i < LATENT_CHANNELS * HISTOGRAM_SIZE; ++i) {
            parameters.dev_unet_input[event_offset + i] = s_aggregated_kde[i];
        }
        
        // Initialize histogram output to zero for now (will be U-Net output)
        for (unsigned bin = 0; bin < HISTOGRAM_SIZE; ++bin) {
            parameters.dev_pv_histogram[event_id * HISTOGRAM_SIZE + bin] = 0.0f;
        }
    }
}

// Extract 9-dimensional track features for neural network input
__device__ void extract_track_features(
    const Allen::Views::Physics::KalmanState& state,
    float* features) 
{
    // Extract position and direction
    features[0] = state.x();     // x position
    features[1] = state.y();     // y position  
    features[2] = state.z();     // z position
    features[3] = state.tx();    // x direction
    features[4] = state.ty();    // y direction
    
    // Extract diagonal covariance matrix elements
    features[5] = state.c00();   // xx covariance
    features[6] = state.c11();   // yy covariance
    features[7] = state.c22();   // zz covariance (if available)
    features[8] = state.c33();   // txty covariance (if available)
}

// Assign track to one or two intervals based on z-coordinate
__device__ void assign_track_intervals(
    float z_poca,
    int& interval1,
    int& interval2,
    bool& has_second) 
{
    const float interval_width = (Z_MAX - Z_MIN) / NUM_INTERVALS;
    const float z_normalized = (z_poca - Z_MIN) / interval_width;
    
    interval1 = __float2int_rd(z_normalized);
    interval1 = max(0, min(interval1, static_cast<int>(NUM_INTERVALS) - 1));
    
    // Check if track spans multiple intervals
    const float overlap_threshold = 0.1f;
    const float fraction = z_normalized - interval1;
    
    has_second = false;
    if (fraction > (1.0f - overlap_threshold) && interval1 < static_cast<int>(NUM_INTERVALS) - 1) {
        interval2 = interval1 + 1;
        has_second = true;
    } else if (fraction < overlap_threshold && interval1 > 0) {
        interval2 = interval1 - 1;
        has_second = true;
    }
}

// Calculate point of closest approach (POCA) to beam line
__device__ bool calculate_poca(
    const Allen::Views::Physics::KalmanState& state,
    float& poca_x,
    float& poca_y,
    float& poca_z) 
{
    // Simple POCA calculation assuming beam line at origin
    const float x = state.x();
    const float y = state.y();
    const float z = state.z();
    const float tx = state.tx();
    const float ty = state.ty();
    
    // Calculate t parameter for closest approach
    const float t = -(x * tx + y * ty) / (tx * tx + ty * ty + 1e-6f);
    
    // Calculate POCA coordinates
    poca_x = x + t * tx;
    poca_y = y + t * ty;
    poca_z = z + t;
    
    // Basic validity check
    return (fabsf(poca_z) < 1000.0f);
}

// Placeholder FC forward pass - to be implemented in phase 3
__device__ void fc_forward_pass(
    const float* input,
    float* output,
    const float* weights,
    const float* biases) 
{
    // Placeholder implementation - will be implemented in phase 3
    for (unsigned i = 0; i < FC_OUTPUT_SIZE; ++i) {
        output[i] = 0.0f;
    }
}

// Placeholder softplus activation - to be implemented in phase 3
__device__ void softplus_activation(
    float* data,
    unsigned size) 
{
    // Placeholder implementation - will be implemented in phase 3
    for (unsigned i = 0; i < size; ++i) {
        data[i] = fmaxf(0.0f, data[i]); // Simple ReLU for now
    }
}

} // namespace PVInference
