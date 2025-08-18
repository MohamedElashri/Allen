#include "PVInference.cuh"
#include <cuda_runtime.h>

INSTANTIATE_ALGORITHM(PVInference::PVInference_t)

// Static initialization of weight loader
namespace {
    struct WeightLoaderInit {
        WeightLoaderInit() {
            if (!PVInference::AllenWeightLoader::initialize()) {
                printf("Warning: Failed to initialize AllenWeightLoader\n");
            }
        }
    };
    static WeightLoaderInit weight_init;
}

namespace PVInference {

// Set memory allocation sizes for all intermediate tensors
void PVInference_t::set_arguments_size(
    ArgumentReferences<Parameters> arguments, 
    const RuntimeOptions&, 
    const Constants&) const 
{
    const auto number_of_events = first<host_number_of_events_t>(arguments);
    const auto max_tracks = m_max_tracks_per_event;
    
    // Track processing tensors - Allen allocates for events in current slice
    set_size<dev_track_features_t>(arguments, number_of_events * max_tracks * INPUT_FEATURES);
    set_size<dev_track_masks_t>(arguments, number_of_events * max_tracks);
    set_size<dev_interval_assignments_t>(arguments, number_of_events * max_tracks * 2); // up to 2 intervals per track
    
    // FC layer intermediate outputs (6 layers: 9→20→20→20→20→20→800) - reduced max_tracks from 2048 to 512
    set_size<dev_fc_layer1_t>(arguments, number_of_events * max_tracks * FC_HIDDEN_SIZE);        // 20
    set_size<dev_fc_layer2_t>(arguments, number_of_events * max_tracks * FC_HIDDEN_SIZE);        // 20
    set_size<dev_fc_layer3_t>(arguments, number_of_events * max_tracks * FC_HIDDEN_SIZE);        // 20
    set_size<dev_fc_layer4_t>(arguments, number_of_events * max_tracks * FC_HIDDEN_SIZE);        // 20
    set_size<dev_fc_layer5_t>(arguments, number_of_events * max_tracks * FC_HIDDEN_SIZE);        // 20
    set_size<dev_fc_layer6_t>(arguments, number_of_events * max_tracks * FC_OUTPUT_SIZE);        // 800 (8 x 100)
    
    // Interval processing tensors - per event in current slice
    set_size<dev_interval_kde_t>(arguments, number_of_events * NUM_INTERVALS * LATENT_CHANNELS * HISTOGRAM_SIZE); // 40 x 8 x 100
    set_size<dev_aggregated_kde_t>(arguments, number_of_events * LATENT_CHANNELS * HISTOGRAM_SIZE);               // 8 x 100
    
    // U-Net processing tensors - per event in current slice
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
    
    // Neural network weights - calculate total sizes needed
    // FC layers: (9*20 + 20*20 + 20*20 + 20*20 + 20*20 + 20*800) = (180 + 400 + 400 + 400 + 400 + 16000) = 17780 weights
    constexpr unsigned fc_total_weights = (9 * 20) + (20 * 20) + (20 * 20) + (20 * 20) + (20 * 20) + (20 * 800);
    // FC biases: 20 + 20 + 20 + 20 + 20 + 800 = 920 biases
    constexpr unsigned fc_total_biases = 20 + 20 + 20 + 20 + 20 + 800;
    
    set_size<dev_fc_weights_t>(arguments, fc_total_weights);
    set_size<dev_fc_biases_t>(arguments, fc_total_biases);
    
    // U-Net weights allocation (approximation - will be updated based on actual weight counts)
    constexpr unsigned unet_approx_weights = 100000;  // Rough estimate, will refine
    constexpr unsigned unet_approx_biases = 1000;     // Rough estimate, will refine
    
    set_size<dev_unet_weights_t>(arguments, unet_approx_weights);
    set_size<dev_unet_biases_t>(arguments, unet_approx_biases);
}

// Main algorithm operator
void PVInference_t::operator()(
    const ArgumentReferences<Parameters>& arguments,
    const RuntimeOptions&,
    const Constants&,
    const Allen::Context& context) const 
{
    // Initialize and load weights to device
    static bool weights_loaded = false;
    if (!weights_loaded) {
        if (!AllenWeightLoader::initialize()) {
            printf("ERROR: Failed to initialize weight loader\n");
            return;
        }
        
        // Load weights to device tensors
        auto fc_weights = data<dev_fc_weights_t>(arguments);
        auto fc_biases = data<dev_fc_biases_t>(arguments);
        auto unet_weights = data<dev_unet_weights_t>(arguments);
        auto unet_biases = data<dev_unet_biases_t>(arguments);
        
        // Load FC weights and biases to device
        load_fc_weights_to_device(fc_weights, fc_biases, context);
        
        // Load U-Net weights and biases to device
        load_unet_weights_to_device(unet_weights, unet_biases, context);
        
        weights_loaded = true;
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
    
    // Get tracks for this event - correct Allen pattern
    const auto velo_tracks_view = parameters.dev_velo_tracks_view[event_id];
    const auto velo_states_view = parameters.dev_velo_states_view[event_id];
    
    const unsigned num_tracks = velo_tracks_view.size();
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
        // Get track and state using correct Allen pattern
        const auto track = velo_tracks_view.track(track_idx);
        const auto state = velo_states_view.state(track.track_index());
        
        // Extract track features (9D: x, y, z, tx, ty, covariance diagonal)
        float features[INPUT_FEATURES];
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
        
        // Access device weights and biases from parameters
        const float* dev_fc_weights = parameters.dev_fc_weights;
        const float* dev_fc_biases = parameters.dev_fc_biases;
        
        // Calculate weight offsets for each layer
        constexpr unsigned layer_weight_offsets[6] = {
            0,                              // Layer 1: offset 0
            9 * 20,                         // Layer 2: offset 180  
            9 * 20 + 20 * 20,              // Layer 3: offset 580
            9 * 20 + 2 * 20 * 20,          // Layer 4: offset 980
            9 * 20 + 3 * 20 * 20,          // Layer 5: offset 1380
            9 * 20 + 4 * 20 * 20           // Layer 6: offset 1780
        };
        
        constexpr unsigned layer_bias_offsets[6] = {
            0,      // Layer 1: offset 0
            20,     // Layer 2: offset 20
            40,     // Layer 3: offset 40
            60,     // Layer 4: offset 60
            80,     // Layer 5: offset 80
            100     // Layer 6: offset 100
        };
        
        // Layer 1: 9 → 20
        fc_forward_layer(features, dev_fc_weights + layer_weight_offsets[0], 
                        dev_fc_biases + layer_bias_offsets[0], 
                        layer_outputs[0], INPUT_FEATURES, FC_HIDDEN_SIZE);
        
        // Layers 2-5: 20 → 20
        for (int layer = 1; layer < 5; ++layer) {
            fc_forward_layer(layer_outputs[layer-1], 
                           dev_fc_weights + layer_weight_offsets[layer], 
                           dev_fc_biases + layer_bias_offsets[layer], 
                           layer_outputs[layer], FC_HIDDEN_SIZE, FC_HIDDEN_SIZE);
        }
        
        // Layer 6: 20 → 800 (8 channels × 100 bins) - no ReLU for final layer
        fc_forward_layer(layer_outputs[4], 
                        dev_fc_weights + layer_weight_offsets[5], 
                        dev_fc_biases + layer_bias_offsets[5], 
                        layer_outputs[5], FC_HIDDEN_SIZE, FC_OUTPUT_SIZE, false);
        
        // Apply per-interval softplus + 0.001 scaling (matches Python behavior)
        for (int i = 0; i < FC_OUTPUT_SIZE; ++i) {
            float softplus_result = logf(1.0f + expf(layer_outputs[5][i])); // softplus(x) = ln(1 + e^x)
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

// Apply softplus activation to array - adapted from UpperLimit
__device__ void apply_softplus_activation(
    float* data,
    unsigned size) 
{
    for (unsigned i = 0; i < size; ++i) {
        data[i] = softplus_activation(data[i]);
    }
}

// U-Net CUDA kernels - adapted from UpperLimit

// Conv1D kernel - core U-Net convolution operation
__global__ void conv1d_kernel(
    float* input, float* weight, float* bias, float* output,
    int batch_size, int in_channels, int out_channels, int length, int kernel_size) 
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int total_outputs = batch_size * out_channels * length;
    
    if (idx < total_outputs) {
        // Decode indices
        int batch_idx = idx / (out_channels * length);
        int remainder = idx % (out_channels * length);
        int out_ch_idx = remainder / length;
        int pos_idx = remainder % length;
        
        float sum = bias[out_ch_idx];
        int padding = kernel_size / 2;
        
        // Apply convolution with padding
        for (int in_ch = 0; in_ch < in_channels; ++in_ch) {
            for (int k = 0; k < kernel_size; ++k) {
                int input_pos = pos_idx - padding + k;
                if (input_pos >= 0 && input_pos < length) {
                    int input_offset = batch_idx * in_channels * length + in_ch * length + input_pos;
                    int weight_offset = out_ch_idx * in_channels * kernel_size + in_ch * kernel_size + k;
                    sum += input[input_offset] * weight[weight_offset];
                }
            }
        }
        
        output[idx] = sum;
    }
}

// BatchNorm1D kernel - U-Net normalization layer
__global__ void batch_norm1d_kernel(
    float* input, float* weight, float* bias,
    float* running_mean, float* running_var, float* output,
    int batch_size, int channels, int length, float eps) 
{
    int batch_idx = blockIdx.x;
    int ch_idx = blockIdx.y;
    int pos_idx = threadIdx.x;
    
    if (batch_idx < batch_size && ch_idx < channels && pos_idx < length) {
        float mean = running_mean[ch_idx];
        float var = running_var[ch_idx];
        float std_dev = sqrtf(var + eps);
        
        int input_offset = batch_idx * channels * length + ch_idx * length + pos_idx;
        float input_val = input[input_offset];
        float normalized = (input_val - mean) / std_dev;
        float result = weight[ch_idx] * normalized + bias[ch_idx];
        
        output[input_offset] = result;
    }
}

// ReLU activation kernel
__global__ void relu_kernel(float* input, float* output, int size) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx < size) {
        output[idx] = fmaxf(0.0f, input[idx]);
    }
}

// MaxPool1D kernel for U-Net downsampling
__global__ void max_pool1d_kernel(
    float* input, float* output, 
    int batch_size, int channels, int input_length, int pool_size) 
{
    int batch_idx = blockIdx.x;
    int ch_idx = blockIdx.y;
    int out_pos = threadIdx.x;
    int output_length = input_length / pool_size;
    
    if (batch_idx < batch_size && ch_idx < channels && out_pos < output_length) {
        float max_val = -1e10f;
        int start_pos = out_pos * pool_size;
        
        for (int i = 0; i < pool_size; ++i) {
            int input_pos = start_pos + i;
            if (input_pos < input_length) {
                int input_offset = batch_idx * channels * input_length + ch_idx * input_length + input_pos;
                max_val = fmaxf(max_val, input[input_offset]);
            }
        }
        
        int output_offset = batch_idx * channels * output_length + ch_idx * output_length + out_pos;
        output[output_offset] = max_val;
    }
}

// TransposeConv1D kernel for U-Net upsampling - FIXED VERSION from UpperLimit
__global__ void transpose_conv1d_kernel(
    float* input, float* weight, float* bias, float* output,
    int batch_size, int in_channels, int out_channels, 
    int input_length, int output_length, int kernel_size, 
    int stride, int padding, int output_padding) 
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int total_outputs = batch_size * out_channels * output_length;
    
    if (idx < total_outputs) {
        // Decode indices
        int batch_idx = idx / (out_channels * output_length);
        int remainder = idx % (out_channels * output_length);
        int out_ch_idx = remainder / output_length;
        int out_pos = remainder % output_length;
        
        float sum = bias[out_ch_idx];
        
        // Transpose convolution: for each output position, find contributing input positions
        for (int in_ch = 0; in_ch < in_channels; ++in_ch) {
            for (int k = 0; k < kernel_size; ++k) {
                // FIXED FORMULA from UpperLimit debugging
                int input_pos = (out_pos - k + padding) / stride;
                
                // FIXED ALIGNMENT CHECK from UpperLimit debugging
                if (input_pos >= 0 && input_pos < input_length && 
                    (out_pos - k + padding) % stride == 0) {
                    
                    int input_offset = batch_idx * in_channels * input_length + 
                                     in_ch * input_length + input_pos;
                    // FIXED WEIGHT LAYOUT: PyTorch format [in_ch, out_ch, kernel]
                    int weight_offset = in_ch * out_channels * kernel_size + 
                                      out_ch_idx * kernel_size + k;
                    
                    sum += input[input_offset] * weight[weight_offset];
                }
            }
        }
        
        output[idx] = sum;
    }
}

// Tensor concatenation kernel for U-Net skip connections
__global__ void concatenate_kernel(
    float* input1, float* input2, float* output,
    int batch_size, int channels1, int channels2, int length) 
{
    int batch_idx = blockIdx.x;
    int ch_idx = blockIdx.y;
    int pos_idx = threadIdx.x;
    
    if (batch_idx < batch_size && pos_idx < length) {
        if (ch_idx < channels1) {
            // Copy from input1
            int input1_offset = batch_idx * channels1 * length + ch_idx * length + pos_idx;
            int output_offset = batch_idx * (channels1 + channels2) * length + ch_idx * length + pos_idx;
            output[output_offset] = input1[input1_offset];
        } else if (ch_idx < channels1 + channels2) {
            // Copy from input2
            int ch2_idx = ch_idx - channels1;
            int input2_offset = batch_idx * channels2 * length + ch2_idx * length + pos_idx;
            int output_offset = batch_idx * (channels1 + channels2) * length + ch_idx * length + pos_idx;
            output[output_offset] = input2[input2_offset];
        }
    }
}

// Weight loading implementations
void load_fc_weights_to_device(
    float* dev_fc_weights,
    float* dev_fc_biases,
    const Allen::Context& context) 
{
    // FC layer weight and bias names in order
    const char* fc_weight_names[] = {
        "layer1_weight", "layer2_weight", "layer3_weight", 
        "layer4_weight", "layer5_weight", "layer6_weight"
    };
    const char* fc_bias_names[] = {
        "layer1_bias", "layer2_bias", "layer3_bias",
        "layer4_bias", "layer5_bias", "layer6_bias"
    };
    
    // Copy FC weights to device
    unsigned weight_offset = 0;
    for (int i = 0; i < 6; i++) {
        const float* layer_weights = AllenWeightLoader::getLayerWeights(fc_weight_names[i]);
        unsigned weight_size = AllenWeightLoader::getLayerSize(fc_weight_names[i]);
        
        if (layer_weights && weight_size > 0) {
            cudaMemcpy(dev_fc_weights + weight_offset, layer_weights, weight_size * sizeof(float), cudaMemcpyHostToDevice);
            weight_offset += weight_size;
        }
    }
    
    // Copy FC biases to device
    unsigned bias_offset = 0;
    for (int i = 0; i < 6; i++) {
        const float* layer_biases = AllenWeightLoader::getLayerWeights(fc_bias_names[i]);
        unsigned bias_size = AllenWeightLoader::getLayerSize(fc_bias_names[i]);
        
        if (layer_biases && bias_size > 0) {
            cudaMemcpy(dev_fc_biases + bias_offset, layer_biases, bias_size * sizeof(float), cudaMemcpyHostToDevice);
            bias_offset += bias_size;
        }
    }
}

void load_unet_weights_to_device(
    float* dev_unet_weights,
    float* dev_unet_biases,
    const Allen::Context& context) 
{
    // U-Net layer names (simplified - will expand based on actual weight file structure)
    const char* unet_weight_names[] = {
        "rcbn1_conv_weight", "rcbn1_bn_weight", "rcbn1_bn_bias",
        "rcbn2_conv_weight", "rcbn2_bn_weight", "rcbn2_bn_bias",
        "rcbn3_conv_weight", "rcbn3_bn_weight", "rcbn3_bn_bias",
        "up1_transpose_weight", "up1_conv_weight", "up1_bn_weight", "up1_bn_bias",
        "up2_transpose_weight", "up2_conv_weight", "up2_bn_weight", "up2_bn_bias",
        "out_intermediate_weight", "out_intermediate_bias",
        "outc_weight", "outc_bias"
    };
    
    // Copy U-Net weights to device (simplified version)
    unsigned weight_offset = 0;
    for (const char* weight_name : unet_weight_names) {
        const float* layer_weights = AllenWeightLoader::getLayerWeights(weight_name);
        unsigned weight_size = AllenWeightLoader::getLayerSize(weight_name);
        
        if (layer_weights && weight_size > 0 && weight_offset + weight_size < 100000) {
            cudaMemcpy(dev_unet_weights + weight_offset, layer_weights, weight_size * sizeof(float), cudaMemcpyHostToDevice);
            weight_offset += weight_size;
        }
    }
}

} // namespace PVInference
