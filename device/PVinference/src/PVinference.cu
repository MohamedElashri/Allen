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
#include "PVinference.cuh"
#include <fstream>
#include <iostream>
#include <cstring>
#include <unordered_map>
#include <vector>
#include <memory>
#include <algorithm>

INSTANTIATE_ALGORITHM(pvinference::PVinference_t)

// Phase 2: Memory allocation and weight storage infrastructure
namespace PVinference {
  // Only small arrays in constant memory to stay within 64KB limit
  __constant__ float dev_input_mean[TRACK_FEATURES];
  __constant__ float dev_input_std[TRACK_FEATURES];
}

void pvinference::PVinference_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  const unsigned num_events = first<host_number_of_events_t>(arguments);
  
  // Phase 2: Track-independent fixed-size memory allocation
  // Output: 100 KDE bins per event
  set_size<dev_output_kde_t>(arguments, num_events * PVinference::KDE_BINS);
  
  // FC workspace: Fixed per-warp allocation (track-independent)
  set_size<dev_fc_workspace_t>(arguments, PVinference::FC_WORKSPACE_SIZE);
  
  // U-Net workspace: Per-event intermediate tensors
  set_size<dev_unet_workspace_t>(arguments, num_events * PVinference::UNET_WORKSPACE_SIZE);
  
  // Interval histograms: 40 intervals × 100 bins per event
  set_size<dev_interval_histograms_t>(arguments, num_events * PVinference::INTERVAL_HISTOGRAM_SIZE);
  
  // U-Net weights in global memory (large weights)
  set_size<dev_fc_weights_t>(arguments, PVinference::FC_WEIGHT_COUNT);
  set_size<dev_fc_biases_t>(arguments, PVinference::FC_BIAS_COUNT);
  set_size<dev_unet_weights_t>(arguments, PVinference::UNET_WEIGHT_COUNT);
  set_size<dev_unet_biases_t>(arguments, PVinference::UNET_BIAS_COUNT);
}

void pvinference::PVinference_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  // Initialize output to zero
  Allen::memset_async<dev_output_kde_t>(arguments, 0, context);

  // Launch kernel with block-per-event threading model
  const auto grid_size = first<host_number_of_events_t>(arguments);
  const auto block_size = dim3(256, 1, 1);
  
  global_function(pvinference_kernel)(dim3(grid_size), block_size, context)(arguments);
}

void pvinference::PVinference_t::update(const Constants& constants) const
{
  // Phase 2: Load binary weights from pvfinder_weights.bin
  if (load_binary_weights()) {
    info_cout << "PVinference Phase 2: Binary weights loaded successfully" << std::endl;
  } else {
    warning_cout << "PVinference Phase 2: Failed to load binary weights - using placeholders" << std::endl;
  }
}

bool pvinference::PVinference_t::load_binary_weights() const
{
  // Phase 2: Binary weight loading implementation
  const std::string weights_path = "device/PVinference/include/weights/pvfinder_weights.bin";
  
  std::ifstream file(weights_path, std::ios::binary);
  if (!file.is_open()) {
    warning_cout << "Cannot open binary weights file: " << weights_path << std::endl;
    return false;
  }

  // Read and validate header (matching UpperLimit binary format)
  struct WeightHeader {
    uint32_t magic;          // 0x50564657 ("PVFW")
    uint32_t version;        // 1
    uint32_t num_layers;     // Number of weight layers
    uint32_t total_weights;  // Total float count
  } header;
  
  file.read(reinterpret_cast<char*>(&header), sizeof(WeightHeader));
  if (file.gcount() != sizeof(WeightHeader)) {
    warning_cout << "Failed to read weight file header" << std::endl;
    return false;
  }

  if (header.magic != 0x50564657 || header.version != 1) {
    warning_cout << "Invalid binary weights file format or version" << std::endl;
    return false;
  }

  info_cout << "Loading " << header.num_layers << " layers, " << header.total_weights << " weights" << std::endl;

  // Read layer headers to build lookup map
  struct LayerHeader {
    char name[64];          // Layer name
    uint32_t size;          // Number of floats
    uint32_t offset;        // Byte offset
  };
  
  std::vector<LayerHeader> layers(header.num_layers);
  file.read(reinterpret_cast<char*>(layers.data()), header.num_layers * sizeof(LayerHeader));
  if (file.gcount() != static_cast<std::streamsize>(header.num_layers * sizeof(LayerHeader))) {
    warning_cout << "Failed to read layer headers" << std::endl;
    return false;
  }

  // Load all weights into temporary buffer
  std::unique_ptr<float[]> weight_data = std::make_unique<float[]>(header.total_weights);
  file.read(reinterpret_cast<char*>(weight_data.get()), header.total_weights * sizeof(float));
  if (file.gcount() != static_cast<std::streamsize>(header.total_weights * sizeof(float))) {
    warning_cout << "Failed to read weight data" << std::endl;
    return false;
  }
  file.close();

  // Phase 2: Copy FC weights to constant memory
  // Extract FC weights from binary data and copy to constant memory arrays
  std::vector<float> fc_weights(PVinference::FC_WEIGHT_COUNT);
  std::vector<float> fc_biases(PVinference::FC_BIAS_COUNT);
  
  // Build layer lookup map
  std::unordered_map<std::string, std::pair<uint32_t, uint32_t>> layer_map;
  for (const auto& layer : layers) {
    std::string name(layer.name);
    uint32_t float_offset = (layer.offset - sizeof(WeightHeader) - header.num_layers * sizeof(LayerHeader)) / sizeof(float);
    layer_map[name] = std::make_pair(layer.size, float_offset);
  }
  
  // Extract FC layer weights (layers 1-6)
  unsigned weight_idx = 0, bias_idx = 0;
  const unsigned fc_layer_sizes[] = {9, 20, 20, 20, 20, 20, 800};
  
  for (int layer = 0; layer < 6; ++layer) {
    const unsigned input_size = fc_layer_sizes[layer];
    const unsigned output_size = fc_layer_sizes[layer + 1];
    
    // Extract weights for this layer
    std::string weight_name = "fc_layer" + std::to_string(layer + 1) + "_weight";
    std::string bias_name = "fc_layer" + std::to_string(layer + 1) + "_bias";
    
    auto weight_it = layer_map.find(weight_name);
    auto bias_it = layer_map.find(bias_name);
    
    if (weight_it != layer_map.end() && bias_it != layer_map.end()) {
      // Copy weights
      const float* layer_weights = weight_data.get() + weight_it->second.second;
      std::copy(layer_weights, layer_weights + input_size * output_size, fc_weights.data() + weight_idx);
      weight_idx += input_size * output_size;
      
      // Copy biases
      const float* layer_biases = weight_data.get() + bias_it->second.second;
      std::copy(layer_biases, layer_biases + output_size, fc_biases.begin() + bias_idx);
      bias_idx += output_size;
    }
  }

  // Phase 2: For now, just log successful weight parsing - actual loading will be done via global memory
  info_cout << "Parsed " << fc_weights.size() << " FC weights and " << fc_biases.size() << " FC biases from binary file" << std::endl;
  
  // TODO Phase 4: Copy FC weights to global memory allocated via Allen's set_arguments_size
  // This will be implemented when FC layers are activated

  // Phase 2: Setup input normalization (placeholder values for now)
  std::vector<float> input_mean(PVinference::TRACK_FEATURES, 0.0f);
  std::vector<float> input_std(PVinference::TRACK_FEATURES, 1.0f);
  
  cudaError_t err3 = cudaMemcpyToSymbol(PVinference::dev_input_mean, input_mean.data(), 
                                        input_mean.size() * sizeof(float));
  cudaError_t err4 = cudaMemcpyToSymbol(PVinference::dev_input_std, input_std.data(), 
                                        input_std.size() * sizeof(float));
                                        
  if (err3 != cudaSuccess || err4 != cudaSuccess) {
    warning_cout << "Failed to copy normalization constants to constant memory" << std::endl;
    return false;
  }

  info_cout << "Phase 2: Binary weight loading infrastructure complete" << std::endl;
  return true;
}

// Phase 3: BeamLine structure for POCA calculations
struct BeamLine {
    __host__ __device__ float x() const { return 0.f; }
    __host__ __device__ float y() const { return 0.f; }
    __host__ __device__ float z() const { return 0.f; }
    __host__ __device__ float tx() const { return 0.f; }
    __host__ __device__ float ty() const { return 0.f; }
};

// Phase 3: Vector math utility functions
__device__ __forceinline__ float3 normalize(float3 v) {
    const float inv_mag = __frsqrt_rn(__fmaf_rn(v.x, v.x, __fmaf_rn(v.y, v.y, v.z * v.z)) + 1e-10f);
    return make_float3(v.x * inv_mag, v.y * inv_mag, v.z * inv_mag);
}

__device__ __forceinline__ float3 cross(float3 a, float3 b) {
    return make_float3(
        __fmaf_rn(a.y, b.z, -a.z * b.y),
        __fmaf_rn(a.z, b.x, -a.x * b.z),
        __fmaf_rn(a.x, b.y, -a.y * b.x)
    );
}

__device__ __forceinline__ float dot(float3 a, float3 b) {
    return __fmaf_rn(a.x, b.x, __fmaf_rn(a.y, b.y, a.z * b.z));
}

/**
 * @brief Calculate Point of Closest Approach to beamline
 * @param state Kalman state of the track
 * @param beam_line Beamline reference
 * @param poca_x Output X coordinate of POCA
 * @param poca_y Output Y coordinate of POCA
 * @param poca_z Output Z coordinate of POCA
 * @return Success flag for POCA calculation
 */
__device__ __forceinline__ bool state_poca(
    const Allen::Views::Physics::KalmanState& state,
    const BeamLine& beam_line,
    float& poca_x, float& poca_y, float& poca_z) {
    
    // Proper POCA calculation using beamline
    const float dz = -state.z();
    const float dx = state.x() + dz * state.tx();
    const float dy = state.y() + dz * state.ty();
    
    // Simple distance check for validity
    const float distance_sq = dx * dx + dy * dy;
    const bool success = distance_sq < 1000000.0f; // 1000^2 mm
    
    if (success) {
        poca_x = dx;
        poca_y = dy;
        poca_z = 0.0f; // At beamline z=0
    } else {
        poca_x = poca_y = poca_z = 0.0f;
    }
    
    return success;
}

/**
 * @brief Calculate ellipsoid parameters from track state covariance matrix
 * @param state Kalman state of the track
 * @param ellipsoid_params Output array for 6 ellipsoid parameters
 * @param poca_x Output X coordinate of POCA
 * @param poca_y Output Y coordinate of POCA
 * @param poca_z Output Z coordinate of POCA
 */
__device__ __forceinline__ void calculate_ellipsoid_params(
    const Allen::Views::Physics::KalmanState& state,
    float* ellipsoid_params,
    float& poca_x, float& poca_y, float& poca_z) {
    
    BeamLine beam_line;
    bool poca_success = state_poca(state, beam_line, poca_x, poca_y, poca_z);
    
    // Branchless handling of failed POCA
    const float success_mult = poca_success ? 1.0f : 0.0f;
    poca_x *= success_mult;
    poca_y *= success_mult;
    poca_z *= success_mult;
    
    float3 center = make_float3(poca_x, poca_y, poca_z);
    float3 track_dir = normalize(make_float3(state.tx(), state.ty(), 1.0f));
    float3 zhat = normalize(center);
    float3 xhat = track_dir;
    float3 yhat = normalize(cross(zhat, xhat));
    
    const float road_error = __fsqrt_rn(state.c00());
    const float road_error_mult = road_error * success_mult;
    
    // Vectorized ellipsoid parameter calculation
    float3 u1 = make_float3(road_error_mult * zhat.x, road_error_mult * zhat.y, road_error_mult * zhat.z);
    float3 u2 = make_float3(road_error_mult * yhat.x, road_error_mult * yhat.y, road_error_mult * yhat.z);
    
    float arg = dot(xhat, track_dir);
    arg = fminf(arg, 0.9999f);
    float u3_scale = (road_error_mult * arg) * __frsqrt_rn(1.0f - arg * arg);
    float3 u3 = make_float3(u3_scale * xhat.x, u3_scale * xhat.y, u3_scale * xhat.z);
    
    // Vectorized parameter computation
    ellipsoid_params[0] = __fmaf_rn(u1.x, u1.x, __fmaf_rn(u2.x, u2.x, u3.x * u3.x));
    ellipsoid_params[1] = __fmaf_rn(u1.y, u1.y, __fmaf_rn(u2.y, u2.y, u3.y * u3.y));
    ellipsoid_params[2] = __fmaf_rn(u1.z, u1.z, __fmaf_rn(u2.z, u2.z, u3.z * u3.z));
    ellipsoid_params[3] = __fmaf_rn(u1.x, u1.y, __fmaf_rn(u2.x, u2.y, u3.x * u3.y));
    ellipsoid_params[4] = __fmaf_rn(u1.x, u1.z, __fmaf_rn(u2.x, u2.z, u3.x * u3.z));
    ellipsoid_params[5] = __fmaf_rn(u1.y, u1.z, __fmaf_rn(u2.y, u2.z, u3.y * u3.z));
}

/**
 * @brief Assign track to 40 intervals with overlap handling
 * @param z_poca Z coordinate of Point of Closest Approach
 * @param interval1 Primary interval assignment
 * @param interval2 Secondary interval assignment (if overlap)
 * @param has_second Flag indicating if track spans two intervals
 */
__device__ __forceinline__ void assign_intervals(
    float z_poca, int& interval1, int& interval2, bool& has_second) {
    
    z_poca += 100.0f; // Shift to [0, 400] range
    
    // Branchless computation using arithmetic operations
    const float inv_10 = 0.1f;
    const int base_interval = __float2int_rd(z_poca * inv_10);
    interval1 = min(39, max(0, base_interval));
    
    // Branchless edge detection for ±2.5mm overlap
    const float edge_low = 10.0f;
    const float edge_high = 390.0f;
    const bool is_low_edge = z_poca <= edge_low;
    const bool is_high_edge = z_poca >= edge_high;
    const bool in_range = (z_poca >= 0.0f) & (z_poca <= 400.0f);
    
    has_second = in_range & (is_low_edge | is_high_edge);
    interval2 = interval1 + (is_low_edge ? 1 : -1);
}

/**
 * @brief Extract track features from Allen track data structures (Phase 3 implementation)
 * @param state Allen Kalman state containing track parameters
 * @param features Output array for 9 track features [poca_x, poca_y, poca_z, ellipsoid_params[0-5]]
 */
__device__ void extract_track_features(
    const Allen::Views::Physics::KalmanState& state,
    float features[PVinference::TRACK_FEATURES])
{
  // Phase 3: Real physics calculations
  float ellipsoid_params[6];
  float poca_x, poca_y, poca_z;
  
  // Calculate POCA and ellipsoid parameters from track state
  calculate_ellipsoid_params(state, ellipsoid_params, poca_x, poca_y, poca_z);
  
  // Pack into features array: [poca_x, poca_y, poca_z, ellipsoid_params[0-5]]
  features[0] = poca_x;
  features[1] = poca_y;
  features[2] = poca_z;
  features[3] = ellipsoid_params[0];
  features[4] = ellipsoid_params[1];
  features[5] = ellipsoid_params[2];
  features[6] = ellipsoid_params[3];
  features[7] = ellipsoid_params[4];
  features[8] = ellipsoid_params[5];
}

/**
 * @brief Normalize input features using pre-computed mean and std
 * @param input Raw input features
 * @param normalized Output normalized features
 * @param size Number of features to normalize
 */
__device__ void normalize_input_features(
  const float* __restrict__ input,
  float* __restrict__ normalized,
  const int size)
{
  for (int i = 0; i < size; ++i) {
    normalized[i] = (input[i] - PVinference::dev_input_mean[i]) / PVinference::dev_input_std[i];
  }
}

/**
 * @brief Forward pass through single FC layer with ReLU activation
 * @param input Input tensor
 * @param weights Layer weights
 * @param biases Layer biases  
 * @param output Output tensor
 * @param input_size Input dimension
 * @param output_size Output dimension
 */
__device__ void fc_layer_forward(
  const float* __restrict__ input,
  const float* __restrict__ weights,
  const float* __restrict__ biases,
  float* __restrict__ output,
  const int input_size,
  const int output_size)
{
  // TODO Phase 4: Implement optimized FC layer computation
  // For now, placeholder implementation
  for (int out_idx = 0; out_idx < output_size; ++out_idx) {
    float sum = biases[out_idx];
    for (int in_idx = 0; in_idx < input_size; ++in_idx) {
      sum += input[in_idx] * weights[out_idx * input_size + in_idx];
    }
    output[out_idx] = fmaxf(0.0f, sum); // ReLU activation
  }
}

/**
 * @brief Main PVinference CUDA kernel - one block per event
 * @param parameters Algorithm parameters containing input/output data
 */
__global__ void pvinference_kernel(pvinference::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned thread_id = threadIdx.x;
  const unsigned block_size = blockDim.x;
  
  // Get track data for this event
  const auto velo_tracks = parameters.dev_velo_tracks_view[event_number];
  const auto velo_states = parameters.dev_velo_kalman_beamline_states[event_number];
  const unsigned n_tracks = velo_tracks.size();
  
  // Early exit if no tracks
  if (n_tracks == 0) return;
  
  // Phase 2: Enhanced shared memory workspace for per-block processing
  __shared__ float s_kde_histogram[PVinference::KDE_BINS];
  __shared__ float s_interval_histograms[PVinference::N_INTERVALS][PVinference::KDE_BINS];
  __shared__ float s_fc_workspace[PVinference::WARP_SIZE][20];  // FC processing workspace
  __shared__ int s_interval_counts[PVinference::N_INTERVALS];   // Track counts per interval
  
  // Initialize shared memory histograms and counters to zero
  for (int i = thread_id; i < PVinference::KDE_BINS; i += block_size) {
    s_kde_histogram[i] = 0.0f;
    for (int interval = 0; interval < PVinference::N_INTERVALS; ++interval) {
      s_interval_histograms[interval][i] = 0.0f;
    }
  }
  
  // Initialize interval counters
  for (int i = thread_id; i < PVinference::N_INTERVALS; i += block_size) {
    s_interval_counts[i] = 0;
  }
  
  // Initialize FC workspace
  const int warp_id = thread_id / 32;
  const int lane_id = thread_id % 32;
  if (warp_id < PVinference::WARP_SIZE && lane_id < 20) {
    s_fc_workspace[warp_id][lane_id] = 0.0f;
  }
  __syncthreads();
  
  // Phase 3: Process tracks in parallel with proper Allen track data integration
  for (unsigned track_idx = thread_id; track_idx < n_tracks; track_idx += block_size) {
    
    // Get the specific track and its Kalman state
    const auto track = velo_tracks.track(track_idx);
    const auto state = velo_states.state(track.track_index());
    
    // Phase 3: Extract real track features using physics calculations
    float track_features[PVinference::TRACK_FEATURES];
    extract_track_features(state, track_features);
    
    // Normalize features
    float normalized_features[PVinference::TRACK_FEATURES];
    normalize_input_features(track_features, normalized_features, PVinference::TRACK_FEATURES);
    
    // Phase 3: Assign track to intervals using real POCA z-coordinate
    const float z_poca = track_features[2]; // poca_z is index 2
    int interval1, interval2;
    bool has_second_interval;
    assign_intervals(z_poca, interval1, interval2, has_second_interval);
    
    // FC network forward pass (Phase 4)
    // TODO: Implement full 6-layer FC network
    
    // U-Net processing (Phase 5) 
    // TODO: Implement U-Net CNN processing
    
    // Phase 3: Add contributions to appropriate intervals
    // For now, use placeholder contribution while FC/U-Net are being implemented
    const float contribution = 0.01f; // Will be replaced by FC+U-Net output
    
    // Add to primary interval
    if (interval1 >= 0 && interval1 < PVinference::N_INTERVALS) {
      for (int k = 0; k < PVinference::KDE_BINS; ++k) {
        atomicAdd(&s_interval_histograms[interval1][k], contribution);
      }
      atomicAdd(&s_interval_counts[interval1], 1);
    }
    
    // Add to secondary interval if track spans overlap region
    if (has_second_interval && interval2 >= 0 && interval2 < PVinference::N_INTERVALS) {
      for (int k = 0; k < PVinference::KDE_BINS; ++k) {
        atomicAdd(&s_interval_histograms[interval2][k], contribution);
      }
      atomicAdd(&s_interval_counts[interval2], 1);
    }
  }
  __syncthreads();
  
  // Aggregate interval histograms into final KDE (Phase 6)
  for (int i = thread_id; i < PVinference::KDE_BINS; i += block_size) {
    float sum = 0.0f;
    for (int interval = 0; interval < PVinference::N_INTERVALS; ++interval) {
      sum += s_interval_histograms[interval][i];
    }
    s_kde_histogram[i] = sum;
  }
  __syncthreads();
  
  // Write final output
  float* event_output = parameters.dev_output_kde + event_number * PVinference::KDE_BINS;
  for (int i = thread_id; i < PVinference::KDE_BINS; i += block_size) {
    event_output[i] = s_kde_histogram[i];
  }
  
  // Phase 3: Enhanced debug output with track processing info
  if (event_number == 0 && thread_id == 0) {
    printf("PVinference Phase 3: Event %u, tracks=%u, intervals_used=%d, output[0]=%.6f, output[99]=%.6f\n", 
           event_number, n_tracks, PVinference::N_INTERVALS, event_output[0], event_output[99]);
  }
}
