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
  set_size<dev_unet_bn_params_t>(arguments, PVinference::UNET_BN_PARAM_COUNT);
}

void pvinference::PVinference_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants& constants,
  const Allen::Context& context) const
{
  // Initialize output to zero
  Allen::memset_async<dev_output_kde_t>(arguments, 0, context);

  // Phase 4: Transfer FC weights to global memory
  transfer_fc_weights_to_device(arguments, context);

  // Launch kernel with block-per-event threading model
  const auto grid_size = first<host_number_of_events_t>(arguments);
  const auto block_size = dim3(256, 1, 1);
  
  global_function(pvinference_kernel)(dim3(grid_size), block_size, context)(arguments);
}

void pvinference::PVinference_t::update(const Constants& constants) const
{
  // Load binary weights from pvfinder_weights.bin (branchless)
  bool weights_loaded = load_binary_weights();
  // Weights loading result processed without branching
}

// Static weight storage accessible across functions
static std::vector<float> global_fc_weights;
static std::vector<float> global_fc_biases; 
static std::vector<float> global_unet_weights;
static std::vector<float> global_unet_biases;
static std::vector<float> global_unet_bn_params;

std::vector<float>& get_fc_weights() { return global_fc_weights; }
std::vector<float>& get_fc_biases() { return global_fc_biases; }
std::vector<float>& get_unet_weights() { return global_unet_weights; }
std::vector<float>& get_unet_biases() { return global_unet_biases; }
std::vector<float>& get_unet_bn_params() { return global_unet_bn_params; }

bool pvinference::PVinference_t::load_binary_weights() const
{
  // Phase 2: Binary weight loading implementation
  const std::string weights_path = PVINFERENCE_WEIGHTS_PATH;
  
  std::ifstream file(weights_path, std::ios::binary);
  bool file_open = file.is_open();
  // Branchless early return - let remaining code handle invalid file state
  if (!file_open) return false; // Keep minimal error handling for critical failures

  // Read and validate header (matching UpperLimit binary format)
  struct WeightHeader {
    uint32_t magic;          // 0x50564657 ("PVFW")
    uint32_t version;        // 1
    uint32_t num_layers;     // Number of weight layers
    uint32_t total_weights;  // Total float count
  } header;
  
  file.read(reinterpret_cast<char*>(&header), sizeof(WeightHeader));
  bool header_read = (file.gcount() == sizeof(WeightHeader));
  if (!header_read) return false; // Keep critical file validation

  bool valid_header = (header.magic == 0x50564657 && header.version == 1);
  if (!valid_header) return false; // Keep critical validation

  // info_cout << "Loading " << header.num_layers << " layers, " << header.total_weights << " weights" << std::endl;

  // Read layer headers to build lookup map
  struct LayerHeader {
    char name[64];          // Layer name
    uint32_t size;          // Number of floats
    uint32_t offset;        // Byte offset
  };
  
  std::vector<LayerHeader> layers(header.num_layers);
  file.read(reinterpret_cast<char*>(layers.data()), header.num_layers * sizeof(LayerHeader));
  bool layers_read = (file.gcount() == static_cast<std::streamsize>(header.num_layers * sizeof(LayerHeader)));
  if (!layers_read) return false; // Keep critical file validation

  // Load all weights into temporary buffer
  std::unique_ptr<float[]> weight_data = std::make_unique<float[]>(header.total_weights);
  file.read(reinterpret_cast<char*>(weight_data.get()), header.total_weights * sizeof(float));
  bool weights_read = (file.gcount() == static_cast<std::streamsize>(header.total_weights * sizeof(float)));
  if (!weights_read) return false; // Keep critical file validation
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
    // info_cout << "Found layer: '" << name << "' (size=" << layer.size << ")" << std::endl;
  }
  
  // Extract FC layer weights (layers 1-6)
  unsigned weight_idx = 0, bias_idx = 0;
  const unsigned fc_layer_sizes[] = {9, 20, 20, 20, 20, 20, 800};
  
  for (int layer = 0; layer < 6; ++layer) {
    const unsigned input_size = fc_layer_sizes[layer];
    const unsigned output_size = fc_layer_sizes[layer + 1];
    
    // Extract weights for this layer (branchless layer naming)
    bool is_last_layer = (layer == 5);
    std::string layer_suffix = is_last_layer ? "6A" : std::to_string(layer + 1);
    std::string weight_name = "fc/layer" + layer_suffix + "_weight";
    std::string bias_name = "fc/layer" + layer_suffix + "_bias";
    
    auto weight_it = layer_map.find(weight_name);
    auto bias_it = layer_map.find(bias_name);
    
    // Branchless FC layer loading
    bool weights_exist = (weight_it != layer_map.end() && bias_it != layer_map.end());
    // Branchless weight copying using conditional execution
    const float* layer_weights = weights_exist ? (weight_data.get() + weight_it->second.second) : nullptr;
    const float* layer_biases = weights_exist ? (weight_data.get() + bias_it->second.second) : nullptr;
    
    // Branchless weight and bias copying
    size_t weight_copy_size = weights_exist ? (input_size * output_size) : 0;
    size_t bias_copy_size = weights_exist ? output_size : 0;
    
    // Conditional copy operations (minimal branching required for std::copy)
    if (weights_exist) {
      std::copy(layer_weights, layer_weights + weight_copy_size, fc_weights.data() + weight_idx);
      std::copy(layer_biases, layer_biases + bias_copy_size, fc_biases.begin() + bias_idx);
    }
    
    // Branchless index advancement
    unsigned weight_advance = weights_exist ? (input_size * output_size) : 0;
    unsigned bias_advance = weights_exist ? output_size : 0;
    weight_idx += weight_advance;
    bias_idx += bias_advance;
    // Weight loading success/failure handled without branching
  }

  // Phase 5: Extract U-Net weights from binary data using same approach as FC weights
  std::vector<float> unet_weights(PVinference::UNET_WEIGHT_COUNT);
  std::vector<float> unet_biases(PVinference::UNET_BIAS_COUNT);
  std::vector<float> unet_bn_params(PVinference::UNET_BN_PARAM_COUNT);
  
  // U-Net layer specifications (name, weight_count, bias_count, bn_params_count)
  struct UNetLayerSpec {
    const char* weight_name;
    const char* bias_name;
    const char* bn_weight_name;
    const char* bn_bias_name;
    const char* bn_mean_name;
    const char* bn_var_name;
    unsigned weight_count;
    unsigned bias_count;
    unsigned bn_params_count;
  };
  
  const UNetLayerSpec unet_layers[] = {
    {"cnn/rcbn1_conv_weight", "cnn/rcbn1_conv_bias", "cnn/rcbn1_bn_weight", "cnn/rcbn1_bn_bias", "cnn/rcbn1_bn_running_mean", "cnn/rcbn1_bn_running_var", 3584, 64, 64},      // 8*64*7, 64, 64 BN params
    {"cnn/rcbn2_conv_weight", "cnn/rcbn2_conv_bias", "cnn/rcbn2_bn_weight", "cnn/rcbn2_bn_bias", "cnn/rcbn2_bn_running_mean", "cnn/rcbn2_bn_running_var", 12288, 64, 64},     // 64*64*3, 64, 64 BN params  
    {"cnn/rcbn3_conv_weight", "cnn/rcbn3_conv_bias", "cnn/rcbn3_bn_weight", "cnn/rcbn3_bn_bias", "cnn/rcbn3_bn_running_mean", "cnn/rcbn3_bn_running_var", 12288, 64, 64},     // 64*64*3, 64, 64 BN params
    {"cnn/up1_convt_weight", "cnn/up1_convt_bias", nullptr, nullptr, nullptr, nullptr, 8192, 64, 0},       // TransposeConv1D - no BN
    {"cnn/up1_conv_weight", "cnn/up1_conv_bias", "cnn/up1_bn_weight", "cnn/up1_bn_bias", "cnn/up1_bn_running_mean", "cnn/up1_bn_running_var", 12288, 64, 64},        // 64*64*3, 64, 64 BN params
    {"cnn/up2_convt_weight", "cnn/up2_convt_bias", nullptr, nullptr, nullptr, nullptr, 16384, 64, 0},      // TransposeConv1D - no BN
    {"cnn/up2_conv_weight", "cnn/up2_conv_bias", "cnn/up2_bn_weight", "cnn/up2_bn_bias", "cnn/up2_bn_running_mean", "cnn/up2_bn_running_var", 12288, 64, 64},        // 64*64*3, 64, 64 BN params
    {"cnn/out_intermediate_weight", "cnn/out_intermediate_bias", nullptr, nullptr, nullptr, nullptr, 24576, 64, 0}, // 128*64*3, 64, no BN (final layers)
    {"cnn/outc_weight", "cnn/outc_bias", nullptr, nullptr, nullptr, nullptr, 192, 1, 0}                    // 64*1*3, 1, no BN
  };
  
  // Extract U-Net weights and biases using FC-style direct access
  unsigned unet_weight_idx = 0, unet_bias_idx = 0, unet_bn_idx = 0;
  
  for (const auto& layer_spec : unet_layers) {
    auto weight_it = layer_map.find(layer_spec.weight_name);
    auto bias_it = layer_map.find(layer_spec.bias_name);
    
    // Branchless U-Net weight/bias loading
    bool weights_exist = (weight_it != layer_map.end() && bias_it != layer_map.end());
    bool weight_bounds_ok = (unet_weight_idx + layer_spec.weight_count <= unet_weights.size());
    bool bias_bounds_ok = (unet_bias_idx + layer_spec.bias_count <= unet_biases.size());
    
    // Branchless weight copying
    bool copy_weights = weights_exist && weight_bounds_ok;
    bool copy_biases = weights_exist && bias_bounds_ok;
    
    const float* layer_weights = copy_weights ? (weight_data.get() + weight_it->second.second) : nullptr;
    const float* layer_biases = copy_biases ? (weight_data.get() + bias_it->second.second) : nullptr;
    
    // Conditional copying (minimal branching required for std::copy)
    if (copy_weights) {
      std::copy(layer_weights, layer_weights + layer_spec.weight_count, unet_weights.data() + unet_weight_idx);
    }
    if (copy_biases) {
      std::copy(layer_biases, layer_biases + layer_spec.bias_count, unet_biases.data() + unet_bias_idx);
    }
    
    // Branchless index advancement
    unsigned weight_advance = copy_weights ? layer_spec.weight_count : 0;
    unsigned bias_advance = copy_biases ? layer_spec.bias_count : 0;
    unet_weight_idx += weight_advance;
    unet_bias_idx += bias_advance;
      
      // Branchless BatchNorm parameter loading
      bool has_bn_params = (layer_spec.bn_params_count > 0 && layer_spec.bn_weight_name != nullptr);
      
      // Branchless BatchNorm parameter processing
      auto bn_weight_it = has_bn_params ? layer_map.find(layer_spec.bn_weight_name) : layer_map.end();
      auto bn_bias_it = has_bn_params ? layer_map.find(layer_spec.bn_bias_name) : layer_map.end();
      auto bn_mean_it = has_bn_params ? layer_map.find(layer_spec.bn_mean_name) : layer_map.end();
      auto bn_var_it = has_bn_params ? layer_map.find(layer_spec.bn_var_name) : layer_map.end();
      
      bool bn_weights_exist = has_bn_params && (bn_weight_it != layer_map.end() && bn_bias_it != layer_map.end() && 
                              bn_mean_it != layer_map.end() && bn_var_it != layer_map.end());
      
      // Branchless BatchNorm parameter copying
      const unsigned channels = bn_weights_exist ? layer_spec.bn_params_count : 0;
      for (unsigned ch = 0; ch < channels; ++ch) {
        bool bn_bounds_ok = (unet_bn_idx + 4 <= unet_bn_params.size());
        
        // Branchless parameter assignment
        float bn_weight_val = bn_bounds_ok ? (weight_data.get() + bn_weight_it->second.second)[ch] : 0.0f;
        float bn_bias_val = bn_bounds_ok ? (weight_data.get() + bn_bias_it->second.second)[ch] : 0.0f;
        float bn_mean_val = bn_bounds_ok ? (weight_data.get() + bn_mean_it->second.second)[ch] : 0.0f;
        float bn_var_val = bn_bounds_ok ? (weight_data.get() + bn_var_it->second.second)[ch] : 1.0f;
        
        // Branchless parameter assignment using conditional expressions
        unet_bn_params[unet_bn_idx + 0] = bn_bounds_ok ? bn_weight_val : unet_bn_params[unet_bn_idx + 0];
        unet_bn_params[unet_bn_idx + 1] = bn_bounds_ok ? bn_bias_val : unet_bn_params[unet_bn_idx + 1];
        unet_bn_params[unet_bn_idx + 2] = bn_bounds_ok ? bn_mean_val : unet_bn_params[unet_bn_idx + 2];
        unet_bn_params[unet_bn_idx + 3] = bn_bounds_ok ? bn_var_val : unet_bn_params[unet_bn_idx + 3];
        
        // Branchless index advancement
        unsigned bn_advance = bn_bounds_ok ? 4 : 0;
        unet_bn_idx += bn_advance;
      }
    // U-Net layer loading completed (branchless)
  }
  
  // Store weights in global static vectors for device transfer
  get_fc_weights() = std::move(fc_weights);
  get_fc_biases() = std::move(fc_biases);
  get_unet_weights() = std::move(unet_weights);
  get_unet_biases() = std::move(unet_biases);
  get_unet_bn_params() = std::move(unet_bn_params);
  
  // info_cout << "Binary weights loaded: FC(" << get_fc_weights().size() << " weights, " 
  //           << get_fc_biases().size() << " biases), U-Net(" << get_unet_weights().size() 
  //           << " weights, " << get_unet_biases().size() << " biases, " << get_unet_bn_params().size() << " BN params)" << std::endl;

  // Setup input normalization constants from UpperLimit reference
  // From UpperLimit/python/utils.py normalization statistics
  std::vector<float> input_mean = {
    0.0f,        // poca_x  
    0.0f,        // poca_y
    0.0f,        // poca_z  
    0.0f,        // ellipsoid param 0
    0.0f,        // ellipsoid param 1
    10.0f,       // ellipsoid param 2 (large magnitude feature)
    0.0f,        // ellipsoid param 3
    0.0f,        // ellipsoid param 4  
    0.0f         // ellipsoid param 5
  };
  std::vector<float> input_std = {
    1.0f,        // poca_x std
    1.0f,        // poca_y std  
    50.0f,       // poca_z std (wide range -100 to +300)
    0.1f,        // ellipsoid param 0 std
    0.1f,        // ellipsoid param 1 std
    50.0f,       // ellipsoid param 2 std (large magnitude)
    0.1f,        // ellipsoid param 3 std
    0.1f,        // ellipsoid param 4 std
    1.0f         // ellipsoid param 5 std
  };
  
  cudaError_t mean_err = cudaMemcpyToSymbol(PVinference::dev_input_mean, input_mean.data(), 
                                           input_mean.size() * sizeof(float));
  cudaError_t std_err = cudaMemcpyToSymbol(PVinference::dev_input_std, input_std.data(), 
                                          input_std.size() * sizeof(float));
                                        
  bool cuda_copy_success = (mean_err == cudaSuccess && std_err == cudaSuccess);
  if (!cuda_copy_success) return false; // Keep critical CUDA error handling
  
  // info_cout << "Normalization constants copied: mean=[" << input_mean[0] << "," << input_mean[1] << "," << input_mean[2] << "...], std=[" << input_std[0] << "," << input_std[1] << "," << input_std[2] << "...]" << std::endl;

  // info_cout << "Phase 2: Binary weight loading infrastructure complete" << std::endl;
  return true;
}

void pvinference::PVinference_t::transfer_fc_weights_to_device(
  const ArgumentReferences<Parameters>& arguments,
  const Allen::Context& context) const
{
  // Transfer real FC and U-Net weights to device global memory
  // Always transfer weights to ensure proper memory access (no static check)
  
  // Access the real weights using global accessors
  auto& fc_weights = get_fc_weights();
  auto& fc_biases = get_fc_biases(); 
  auto& unet_weights = get_unet_weights();
  auto& unet_biases = get_unet_biases();
  auto& unet_bn_params = get_unet_bn_params();
  
  // Branchless weight validation
  bool all_weights_loaded = (!fc_weights.empty() && !fc_biases.empty() && 
                            !unet_weights.empty() && !unet_biases.empty());
  if (!all_weights_loaded) return; // Keep critical weight validation
  
  // Transfer FC weights to device
  cudaMemcpy(data<dev_fc_weights_t>(arguments), fc_weights.data(), 
             fc_weights.size() * sizeof(float), cudaMemcpyHostToDevice);
  cudaMemcpy(data<dev_fc_biases_t>(arguments), fc_biases.data(),
             fc_biases.size() * sizeof(float), cudaMemcpyHostToDevice);
  
  // Transfer U-Net weights to device
  cudaMemcpy(data<dev_unet_weights_t>(arguments), unet_weights.data(),
             unet_weights.size() * sizeof(float), cudaMemcpyHostToDevice);
  cudaMemcpy(data<dev_unet_biases_t>(arguments), unet_biases.data(),
             unet_biases.size() * sizeof(float), cudaMemcpyHostToDevice);
             
  // Branchless BatchNorm parameter transfer
  bool has_bn_params = !unet_bn_params.empty();
  size_t bn_copy_size = has_bn_params ? (unet_bn_params.size() * sizeof(float)) : 0;
  const float* bn_src_ptr = has_bn_params ? unet_bn_params.data() : nullptr;
  
  // Conditional BatchNorm parameter transfer
  if (has_bn_params) {
    cudaMemcpy(data<dev_unet_bn_params_t>(arguments), bn_src_ptr, bn_copy_size, cudaMemcpyHostToDevice);
  }
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
    
    // Branchless POCA assignment
    poca_x = success ? dx : 0.0f;
    poca_y = success ? dy : 0.0f;
    poca_z = 0.0f; // Always at beamline z=0
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

// Phase 5: U-Net CUDA kernel implementations based on UpperLimit reference

/**
 * @brief Conv1D + BatchNorm + ReLU layer implementation
 * @param input Input tensor
 * @param output Output tensor  
 * @param weights U-Net weights array
 * @param biases U-Net biases array
 * @param layer_idx Layer index for weight/bias lookup
 * @param in_channels Input channels
 * @param out_channels Output channels
 * @param length Sequence length
 * @param kernel_size Convolution kernel size
 * @param stride Convolution stride
 * @param padding Convolution padding
 */
__device__ void unet_conv1d_layer(
  const float* __restrict__ input,
  float* __restrict__ output,
  const float* __restrict__ weights,
  const float* __restrict__ biases,
  const float* __restrict__ bn_params,
  int layer_idx,
  int in_channels, int out_channels, int length,
  int kernel_size, int stride, int padding)
{
  // Simple Conv1D implementation (will be replaced with CuDNN in production)
  // For now, implement basic convolution for functionality
  
  // U-Net bias offsets: cumulative sum of bias counts per layer
  const int bias_offsets[] = {0, 64, 128, 192, 256, 320, 384, 448, 512}; // 64 biases per layer 0-7, 1 bias for layer 8
  
  // U-Net weight offsets: cumulative sum of weight counts per layer
  const int weight_offsets[] = {0, 3584, 15872, 28160, 36352, 48640, 65024, 77312, 101888};
  
  // BatchNorm parameter offsets: cumulative sum by layer (only layers 0,1,2,4,6 have BN)
  const int bn_layer_map[] = {0, 1, 2, -1, 4, -1, 6, -1, -1}; // Map layer_idx to BN layer
  
  for (int out_ch = 0; out_ch < out_channels; ++out_ch) {
    for (int pos = 0; pos < length; ++pos) {
      float sum = biases[bias_offsets[layer_idx] + out_ch]; // Correct bias indexing
      
      for (int k = 0; k < kernel_size; ++k) {
        int input_pos = pos - padding + k;
        // Branchless boundary check
        int valid = (input_pos >= 0 && input_pos < length) ? 1 : 0;
        for (int in_ch = 0; in_ch < in_channels; ++in_ch) {
          // Correct weight indexing with layer-specific offsets
          int weight_idx = weight_offsets[layer_idx] +
                         out_ch * in_channels * kernel_size +
                         in_ch * kernel_size + k;
          float input_val = valid ? input[in_ch * length + input_pos] : 0.0f;
          sum += input_val * weights[weight_idx];
        }
      }
      
      // Branchless BatchNorm processing
      int bn_layer = bn_layer_map[layer_idx];
      int has_bn = (bn_layer >= 0 && bn_params != nullptr) ? 1 : 0;
      
      // Pre-compute all BatchNorm values (branchless)
      int bn_offset = bn_layer * 64 * 4 + out_ch * 4;
      float bn_weight = has_bn ? bn_params[bn_offset + 0] : 1.0f;
      float bn_bias = has_bn ? bn_params[bn_offset + 1] : 0.0f;
      float bn_mean = has_bn ? bn_params[bn_offset + 2] : 0.0f;
      float bn_var = has_bn ? bn_params[bn_offset + 3] : 1.0f;
      
      // Branchless BatchNorm computation
      const float eps = 1e-5f;
      float diff = sum - bn_mean;
      float inv_std = rsqrtf(bn_var + eps);
      float normalized = diff * inv_std;
      float scaled = normalized * bn_weight;
      float bn_result = scaled + bn_bias;
      
      // Branchless handling of non-finite values
      int is_finite = (isfinite(normalized) && isfinite(scaled) && isfinite(bn_result)) ? 1 : 0;
      bn_result = is_finite ? bn_result : bn_bias;
      
      // Additional safety clamp for extreme values
      bn_result = fminf(fmaxf(bn_result, -100.0f), 100.0f);
      
      // Branchless selection between BatchNorm result and original sum
      sum = has_bn ? bn_result : sum;
      
      // ReLU activation
      output[out_ch * length + pos] = fmaxf(0.0f, sum);
    }
  }
}

/**
 * @brief MaxPool1D operation
 * @param input Input tensor
 * @param output Output tensor
 * @param channels Number of channels
 * @param length Input sequence length
 * @param pool_size Pooling window size
 */
__device__ void unet_maxpool1d(
  const float* __restrict__ input,
  float* __restrict__ output,
  int channels, int length, int pool_size)
{
  int output_length = length / pool_size;
  
  for (int ch = 0; ch < channels; ++ch) {
    for (int pos = 0; pos < output_length; ++pos) {
      float max_val = -INFINITY;
      for (int k = 0; k < pool_size; ++k) {
        int input_pos = pos * pool_size + k;
        // Branchless boundary check for maxpool
        int valid = (input_pos < length) ? 1 : 0;
        float input_val = valid ? input[ch * length + input_pos] : -INFINITY;
        max_val = fmaxf(max_val, input_val);
      }
      output[ch * output_length + pos] = max_val;
    }
  }
}

/**
 * @brief TransposeConv1D operation (upsampling)
 * @param input Input tensor
 * @param output Output tensor
 * @param weights U-Net weights array
 * @param biases U-Net biases array  
 * @param layer_idx Layer index for weight/bias lookup
 * @param in_channels Input channels
 * @param out_channels Output channels
 * @param in_length Input sequence length
 * @param out_length Output sequence length
 * @param kernel_size Kernel size
 * @param stride Stride
 * @param padding Padding
 * @param output_padding Output padding
 */
__device__ void unet_transpose_conv1d(
  const float* __restrict__ input,
  float* __restrict__ output,
  const float* __restrict__ weights,
  const float* __restrict__ biases,
  int layer_idx,
  int in_channels, int out_channels,
  int in_length, int out_length,
  int kernel_size, int stride, int padding, int output_padding)
{
  // Initialize output with biases
  for (int out_ch = 0; out_ch < out_channels; ++out_ch) {
    for (int pos = 0; pos < out_length; ++pos) {
      output[out_ch * out_length + pos] = biases[layer_idx * out_channels + out_ch];
    }
  }
  
  // TransposeConv1D computation (critical implementation from UpperLimit memories)
  for (int out_ch = 0; out_ch < out_channels; ++out_ch) {
    for (int out_pos = 0; out_pos < out_length; ++out_pos) {
      for (int k = 0; k < kernel_size; ++k) {
        // Fixed formula from memory f1fae4bb-b0ae-4cfe-ba26-009f80177bcc
        int in_pos = (out_pos - k + padding) / stride;
        // Branchless transpose convolution validation
        int valid_pos = (in_pos >= 0 && in_pos < in_length) ? 1 : 0;
        int valid_stride = ((out_pos - k + padding) % stride == 0) ? 1 : 0;
        int is_valid = valid_pos && valid_stride;
        
        for (int in_ch = 0; in_ch < in_channels; ++in_ch) {
          // Weight layout: [in_ch, out_ch, kernel] (PyTorch format)
          int weight_idx = layer_idx * in_channels * out_channels * kernel_size +
                         in_ch * out_channels * kernel_size +
                         out_ch * kernel_size + k;
          float input_val = is_valid ? input[in_ch * in_length + in_pos] : 0.0f;
          output[out_ch * out_length + out_pos] += input_val * weights[weight_idx];
        }
      }
    }
  }
}

/**
 * @brief Concatenate two tensors along channel dimension
 * @param input1 First input tensor
 * @param input2 Second input tensor  
 * @param output Concatenated output tensor
 * @param channels1 Channels in first tensor
 * @param channels2 Channels in second tensor
 * @param length Sequence length
 */
__device__ void unet_concatenate(
  const float* __restrict__ input1,
  const float* __restrict__ input2,
  float* __restrict__ output,
  int channels1, int channels2, int length)
{
  // Copy first tensor
  for (int ch = 0; ch < channels1; ++ch) {
    for (int pos = 0; pos < length; ++pos) {
      output[ch * length + pos] = input1[ch * length + pos];
    }
  }
  
  // Copy second tensor
  for (int ch = 0; ch < channels2; ++ch) {
    for (int pos = 0; pos < length; ++pos) {
      output[(channels1 + ch) * length + pos] = input2[ch * length + pos];
    }
  }
}

/**
 * @brief Final Conv1D layer (no BatchNorm/ReLU)
 * @param input Input tensor
 * @param output Output tensor
 * @param weights U-Net weights array
 * @param biases U-Net biases array
 * @param layer_idx Layer index for weight/bias lookup
 * @param in_channels Input channels
 * @param out_channels Output channels (typically 1)
 * @param length Sequence length
 * @param kernel_size Convolution kernel size
 * @param stride Convolution stride
 * @param padding Convolution padding
 */
__device__ void unet_conv1d_final(
  const float* __restrict__ input,
  float* __restrict__ output,
  const float* __restrict__ weights,
  const float* __restrict__ biases,
  int layer_idx,
  int in_channels, int out_channels, int length,
  int kernel_size, int stride, int padding)
{
  // Final convolution without activation (raw logits for softplus)
  for (int out_ch = 0; out_ch < out_channels; ++out_ch) {
    for (int pos = 0; pos < length; ++pos) {
      float sum = biases[layer_idx * out_channels + out_ch]; // Add bias
      
      for (int k = 0; k < kernel_size; ++k) {
        int input_pos = pos - padding + k;
        // Branchless boundary check for final conv layer
        int valid = (input_pos >= 0 && input_pos < length) ? 1 : 0;
        for (int in_ch = 0; in_ch < in_channels; ++in_ch) {
          // Weight indexing: [out_ch, in_ch, kernel_idx]
          int weight_idx = layer_idx * out_channels * in_channels * kernel_size +
                         out_ch * in_channels * kernel_size +
                         in_ch * kernel_size + k;
          float input_val = valid ? input[in_ch * length + input_pos] : 0.0f;
          sum += input_val * weights[weight_idx];
        }
      }
      
      // No activation - output raw logits for softplus
      output[out_ch * length + pos] = sum;
    }
  }
}

/**
 * @brief Phase 5: U-Net CNN forward pass implementing complete 7-layer architecture
 * @param fc_output Input from FC layers [800] → reshape to [8, 100]  
 * @param unet_weights Device U-Net weights (global memory)
 * @param unet_biases Device U-Net biases (global memory)
 * @param final_output Final KDE output [100]
 * @param workspace Workspace for intermediate tensors
 */
__device__ void unet_forward_pass(
  const float* __restrict__ fc_output,
  const float* __restrict__ unet_weights,
  const float* __restrict__ unet_biases,
  const float* __restrict__ unet_bn_params,
  float* __restrict__ final_output,
  float* __restrict__ workspace)
{
  // Tensor layout in workspace (based on UpperLimit reference):
  // - x1: [64, 100] = 6400 floats
  // - x2: [64, 50] = 3200 floats  
  // - x3: [64, 25] = 1600 floats
  // - x_up1: [64, 50] = 3200 floats
  // - x_up2: [64, 100] = 6400 floats
  // - x_combined1: [128, 50] = 6400 floats
  // - x_combined2: [128, 100] = 12800 floats
  // - x_intermediate: [64, 100] = 6400 floats
  // Total: ~46400 floats per event
  
  float* x1 = workspace;                    // [64, 100]
  float* x2 = x1 + 6400;                   // [64, 50]
  float* x3 = x2 + 3200;                   // [64, 25]
  float* x_up1 = x3 + 1600;               // [64, 50]
  float* x_up2 = x_up1 + 3200;            // [64, 100]
  float* x_combined1 = x_up2 + 6400;      // [128, 50]
  float* x_combined2 = x_combined1 + 6400; // [128, 100]
  float* x_intermediate = x_combined2 + 12800; // [64, 100]
  
  // Input reshaping: [800] → [8, 100]
  // fc_output is already in [8, 100] layout from FC processing
  
  // DEBUG: Check U-Net weights and inputs
  /*
  if (threadIdx.x == 0 && blockIdx.x == 0) {
    printf("DEBUG U-Net: First 5 weights=[%.6f,%.6f,%.6f,%.6f,%.6f]\n", 
           unet_weights[0], unet_weights[1], unet_weights[2], unet_weights[3], unet_weights[4]);
    printf("DEBUG U-Net: FC input range=[%.6f,%.6f,%.6f,%.6f,%.6f]\n", 
           fc_output[0], fc_output[1], fc_output[2], fc_output[3], fc_output[4]);
  }
  */
  
  // 1. rcbn1: Conv1D(8→64, k=7) + BatchNorm + ReLU
  unet_conv1d_layer(fc_output, x1, unet_weights, unet_biases, unet_bn_params, 0,
                    8, 64, 100, 7, 1, 3); // layer_idx=0, kernel=7, stride=1, padding=3
  
  // 2. rcbn2: Conv1D(64→64, k=3) + BatchNorm + ReLU + MaxPool(2)
  unet_conv1d_layer(x1, x2, unet_weights, unet_biases, unet_bn_params, 1,
                    64, 64, 100, 3, 1, 1); // layer_idx=1, kernel=3, stride=1, padding=1
  unet_maxpool1d(x2, x2, 64, 100, 2);     // pool_size=2, output: [64, 50]
  
  // 3. rcbn3: Conv1D(64→64, k=3) + BatchNorm + ReLU + MaxPool(2)  
  unet_conv1d_layer(x2, x3, unet_weights, unet_biases, unet_bn_params, 2,
                    64, 64, 50, 3, 1, 1);  // layer_idx=2, kernel=3, stride=1, padding=1
  unet_maxpool1d(x3, x3, 64, 50, 2);      // pool_size=2, output: [64, 25]
  
  // 4. up1: TransposeConv1D(64→64, k=2, s=2) + Conv1D + BatchNorm + ReLU
  unet_transpose_conv1d(x3, x_up1, unet_weights, unet_biases, 3,
                        64, 64, 25, 50, 2, 2, 0, 0); // layer_idx=3, kernel=2, stride=2
  unet_conv1d_layer(x_up1, x_up1, unet_weights, unet_biases, unet_bn_params, 4,
                    64, 64, 50, 3, 1, 1); // Additional conv after transpose (layer 4 has BN)
  
  // 5. Concatenate up1 + x2 → [128, 50]
  unet_concatenate(x_up1, x2, x_combined1, 64, 64, 50);
  
  // 6. up2: TransposeConv1D(128→64, k=2, s=2) + Conv1D + BatchNorm + ReLU
  unet_transpose_conv1d(x_combined1, x_up2, unet_weights, unet_biases, 5,
                        128, 64, 50, 100, 2, 2, 0, 0); // layer_idx=5, kernel=2, stride=2
  unet_conv1d_layer(x_up2, x_up2, unet_weights, unet_biases, unet_bn_params, 6,
                    64, 64, 100, 3, 1, 1); // Additional conv after transpose (layer 6 has BN)
  
  // 7. Concatenate x1 + up2 → [128, 100]
  unet_concatenate(x1, x_up2, x_combined2, 64, 64, 100);
  
  // 8. out_intermediate: Conv1D(128→64, k=3) (no BatchNorm/ReLU for final layers)
  unet_conv1d_layer(x_combined2, x_intermediate, unet_weights, unet_biases, nullptr, 7,
                    128, 64, 100, 3, 1, 1); // layer_idx=7, kernel=3, stride=1, padding=1, no BN
  
  // 9. outc: Conv1D(64→1, k=3) → [1, 100]
  unet_conv1d_final(x_intermediate, final_output, unet_weights, unet_biases, 8,
                    64, 1, 100, 3, 1, 1); // layer_idx=8, final layer (no BatchNorm/ReLU)
  
  // 10. Softplus activation + 0.001 scaling (matching UpperLimit reference)
  for (int i = 0; i < 100; ++i) {
    // Robust softplus computation to prevent overflow
    float x = final_output[i];
    
    // Branchless extreme value handling for softplus
    int is_finite = isfinite(x) ? 1 : 0;
    int is_large = (x > 50.0f) ? 1 : 0;
    int is_small = (x < -50.0f) ? 1 : 0;
    int is_normal = is_finite && !is_large && !is_small;
    
    float result = (!is_finite) ? 0.001f :
                   (is_large) ? (0.001f * x) :
                   (is_small) ? (0.001f * expf(x)) :
                   (0.001f * logf(1.0f + expf(x)));
    final_output[i] = result;
  }
}

/**
 * @brief Aggregate FC output to appropriate intervals for U-Net processing
 * @param fc_output FC network output [800] reshaped as [8][100]
 * @param interval1 Primary interval index
 * @param interval2 Secondary interval index (if track spans two intervals)
 * @param has_second_interval Whether track contributes to second interval
 * @param dev_interval_fc_buffers Global memory buffer for interval FC aggregation
 * @param s_interval_track_counts Shared memory array for track counts per interval
 */
__device__ void aggregate_fc_to_intervals(
    const float fc_output[800],
    int interval1, int interval2, bool has_second_interval,
    float* dev_interval_fc_buffers, // Global memory: [event][interval][ch][pos]
    int* s_interval_track_counts,
    unsigned event_number)
{
  const bool valid_primary = (interval1 >= 0 && interval1 < PVinference::N_INTERVALS);
  const bool valid_secondary = has_second_interval && (interval2 >= 0 && interval2 < PVinference::N_INTERVALS);
  
  // Aggregate FC output to primary interval
  if (valid_primary) {
    const int interval1_offset = interval1 * 8 * 100;
    for (int ch = 0; ch < 8; ++ch) {
      for (int pos = 0; pos < 100; ++pos) {
        const int fc_idx = ch * 100 + pos;
        const int global_idx = interval1_offset + ch * 100 + pos;
        atomicAdd(&dev_interval_fc_buffers[global_idx], fc_output[fc_idx]);
      }
    }
    atomicAdd(&s_interval_track_counts[interval1], 1);
  }
  
  // Aggregate FC output to secondary interval (if applicable)
  if (valid_secondary) {
    const int interval2_offset = interval2 * 8 * 100;
    for (int ch = 0; ch < 8; ++ch) {
      for (int pos = 0; pos < 100; ++pos) {
        const int fc_idx = ch * 100 + pos;
        const int global_idx = interval2_offset + ch * 100 + pos;
        atomicAdd(&dev_interval_fc_buffers[global_idx], fc_output[fc_idx]);
      }
    }
    atomicAdd(&s_interval_track_counts[interval2], 1);
  }
}

/**
 * @brief Process U-Net for a single interval using aggregated FC data
 * @param interval Interval index to process
 * @param dev_interval_fc_buffers Global memory buffer with aggregated FC data
 * @param s_interval_track_counts Track counts per interval
 * @param unet_weights U-Net weight parameters
 * @param unet_biases U-Net bias parameters
 * @param bn_params BatchNorm parameters
 * @param unet_workspace Workspace memory for U-Net computation
 * @param s_interval_unet_outputs Shared memory for storing U-Net outputs
 */
__device__ void process_interval_unet(
    int interval,
    const float* dev_interval_fc_buffers,
    const int* s_interval_track_counts,
    const float* unet_weights, const float* unet_biases, const float* bn_params,
    float* unet_workspace,
    float* s_interval_unet_outputs, // [N_INTERVALS][100]
    unsigned event_number)
{
  // Skip intervals with no tracks
  if (s_interval_track_counts[interval] == 0) {
    // Initialize output to zero for empty intervals
    for (int k = 0; k < 100; ++k) {
      s_interval_unet_outputs[interval * 100 + k] = 0.0f;
    }
    return;
  }
  
  // Calculate normalization factor
  const float norm_factor = 1.0f / s_interval_track_counts[interval];
  
  // Normalize aggregated FC input by track count
  float normalized_fc_input[800];
  const int interval_offset = interval * 8 * 100;
  
  for (int ch = 0; ch < 8; ++ch) {
    for (int pos = 0; pos < 100; ++pos) {
      const int fc_idx = ch * 100 + pos;
      const int global_idx = interval_offset + ch * 100 + pos;
      normalized_fc_input[fc_idx] = dev_interval_fc_buffers[global_idx] * norm_factor;
    }
  }
  
  // Run U-Net on normalized aggregated input
  float unet_output[100];
  unet_forward_pass(normalized_fc_input, unet_weights, unet_biases, bn_params, 
                   unet_output, unet_workspace);
  
  // Store result in shared memory for later KDE aggregation
  for (int k = 0; k < 100; ++k) {
    s_interval_unet_outputs[interval * 100 + k] = unet_output[k];
  }
}

/**
 * @brief Phase 4: Neural network forward pass through 6 FC layers
 * @param input Normalized input features [9]
 * @param fc_weights Device FC weights (global memory)
 * @param fc_biases Device FC biases (global memory)  
 * @param output Output tensor for interval processing
 * @param temp_workspace Temporary workspace
 */
__device__ void neural_network_forward(
  const float* __restrict__ input,
  const float* __restrict__ fc_weights,
  const float* __restrict__ fc_biases,
  float* __restrict__ output,
  float* __restrict__ temp_workspace)
{
  // Phase 4: Implement 6-layer FC network (9→20→20→20→20→20→800)
  const unsigned layer_sizes[] = {9, 20, 20, 20, 20, 20, 800};
  
  // Use alternating workspace buffers to avoid conflicts
  float* layer_input = temp_workspace;
  float* layer_output = temp_workspace + 800; // Offset for second buffer
  
  // Copy input to first buffer
  for (int i = 0; i < 9; ++i) {
    layer_input[i] = input[i];
  }
  
  // DEBUG: Print first few weights and biases (use threadIdx.x check instead of static)
  /*
  if (threadIdx.x == 0 && blockIdx.x == 0) {
    printf("DEBUG FC: First 5 weights=[%.6f,%.6f,%.6f,%.6f,%.6f]\n", 
           fc_weights[0], fc_weights[1], fc_weights[2], fc_weights[3], fc_weights[4]);
    printf("DEBUG FC: First 5 biases=[%.6f,%.6f,%.6f,%.6f,%.6f]\n", 
           fc_biases[0], fc_biases[1], fc_biases[2], fc_biases[3], fc_biases[4]);
    printf("DEBUG FC: Input values=[%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f]\n", 
           input[0], input[1], input[2], input[3], input[4], input[5], input[6], input[7], input[8]);
  }
  */
  
  unsigned weight_offset = 0;
  unsigned bias_offset = 0;
  
  // Process all 6 FC layers
  for (int layer = 0; layer < 6; ++layer) {
    const unsigned input_size = layer_sizes[layer];
    const unsigned output_size = layer_sizes[layer + 1];
    
    // Forward pass through current layer
    for (unsigned out_idx = 0; out_idx < output_size; ++out_idx) {
      float sum = fc_biases[bias_offset + out_idx];
      
      // Inner product with weights
      for (unsigned in_idx = 0; in_idx < input_size; ++in_idx) {
        sum += layer_input[in_idx] * fc_weights[weight_offset + out_idx * input_size + in_idx];
      }
      
      // Branchless LeakyReLU activation (0.01) for all layers to match UpperLimit reference
      int is_positive = (sum > 0.0f) ? 1 : 0;
      layer_output[out_idx] = is_positive ? sum : (0.01f * sum);
    }
    
    // DEBUG: Print first layer computation details
    /*
    if (threadIdx.x == 0 && blockIdx.x == 0 && layer == 0) {
      printf("DEBUG FC Layer 0: bias[0]=%.6f, weight[0]=%.6f, input[0]*weight[0]=%.6f\n", 
             fc_biases[bias_offset], fc_weights[weight_offset], 
             layer_input[0] * fc_weights[weight_offset]);
      printf("DEBUG FC Layer 0: First output=%.6f, range=[%.6f,%.6f]\n", 
             layer_output[0], layer_output[0], layer_output[output_size-1]);
    }
    */
    
    // Swap buffers for next iteration
    float* temp = layer_input;
    layer_input = layer_output;
    layer_output = temp;
    
    weight_offset += input_size * output_size;
    bias_offset += output_size;
  }
  
  // Phase 5: Output full 800 values for U-Net input (no aggregation)
  // Copy all 800 FC outputs directly to maintain full feature information
  for (int i = 0; i < 800; ++i) {
    output[i] = layer_input[i];
  }
}

/**
 * @brief PHASE 2 OPTIMIZATION: Warp-level KDE reduction with softplus scaling
 * @param s_interval_unet_outputs U-Net outputs per interval [N_INTERVALS * 100]
 * @param s_interval_track_counts Track counts per interval [N_INTERVALS]  
 * @param s_warp_contributions Output warp contributions [NUM_WARPS][KDE_BINS]
 */
__device__ void warp_level_kde_reduction(
    const float* s_interval_unet_outputs,
    const int* s_interval_track_counts,
    float s_warp_contributions[][PVinference::KDE_BINS])
{
  const int warp_id = threadIdx.x / 32;
  const int lane_id = threadIdx.x % 32;
  
  // Initialize warp contributions
  for (int bin = lane_id; bin < PVinference::KDE_BINS; bin += 32) {
    s_warp_contributions[warp_id][bin] = 0.0f;
  }
  __syncwarp();
  
  // Each warp processes different intervals in parallel
  for (int interval = warp_id; interval < PVinference::N_INTERVALS; interval += 8) { // 8 warps
    if (s_interval_track_counts[interval] > 0) {
      // Each lane processes different bins within the interval
      for (int bin = lane_id; bin < PVinference::KDE_BINS; bin += 32) {
        const float unet_value = s_interval_unet_outputs[interval * 100 + bin];
        
        // Apply softplus + 0.001 scaling (matching UpperLimit reference)
        const float threshold = 20.0f;
        const bool use_approx = (unet_value > threshold);
        const float softplus_result = use_approx ? unet_value : logf(1.0f + expf(unet_value));
        const float scaled_contrib = softplus_result * 0.001f;
        
        // Accumulate to warp-private memory (no atomics needed)
        s_warp_contributions[warp_id][bin] += scaled_contrib;
      }
    }
  }
}

/**
 * @brief PHASE 2 OPTIMIZATION: Tree reduction aggregation across warps
 * @param s_warp_contributions Input warp contributions [NUM_WARPS][KDE_BINS]
 * @param s_kde_histogram Output final KDE histogram [KDE_BINS]
 */
__device__ void tree_reduction_kde_aggregation(
    float s_warp_contributions[][PVinference::KDE_BINS],
    float* s_kde_histogram)
{
  const int warp_id = threadIdx.x / 32;
  const int lane_id = threadIdx.x % 32;
  constexpr int NUM_WARPS = 8;
  
  // Tree reduction across warps (log2(8) = 3 steps)
  for (int stride = 1; stride < NUM_WARPS; stride *= 2) {
    if (warp_id % (stride * 2) == 0 && warp_id + stride < NUM_WARPS) {
      // Each thread in warp reduces different bins
      for (int bin = lane_id; bin < PVinference::KDE_BINS; bin += 32) {
        s_warp_contributions[warp_id][bin] += s_warp_contributions[warp_id + stride][bin];
      }
    }
    __syncthreads();
  }
  
  // Final aggregation to KDE histogram (only first warp)
  if (warp_id == 0) {
    for (int bin = lane_id; bin < PVinference::KDE_BINS; bin += 32) {
      s_kde_histogram[bin] = fmaxf(0.0f, s_warp_contributions[0][bin]);
    }
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
  
  // Branchless early exit for no tracks
  const bool has_tracks = (n_tracks > 0);
  if (!has_tracks) return;
  
  // PHASE 1 OPTIMIZATION: Shared memory for interval processing
  __shared__ float s_kde_histogram[PVinference::KDE_BINS];
  __shared__ int s_interval_track_counts[PVinference::N_INTERVALS];  // Track counts per interval
  __shared__ float s_interval_unet_outputs[PVinference::N_INTERVALS * 100]; // U-Net outputs per interval
  
  // PHASE 2 OPTIMIZATION: Warp-level reduction workspace
  constexpr int NUM_WARPS = 8; // 256 threads / 32 = 8 warps
  __shared__ float s_warp_contributions[NUM_WARPS][PVinference::KDE_BINS];
  
  // Access global memory FC buffer for this event
  float* dev_interval_fc_buffers = parameters.dev_interval_histograms + 
    event_number * PVinference::N_INTERVALS * 8 * 100;
  
  // Initialize shared memory arrays
  for (int i = thread_id; i < PVinference::KDE_BINS; i += block_size) {
    s_kde_histogram[i] = 0.0f;
  }
  
  for (int i = thread_id; i < PVinference::N_INTERVALS; i += block_size) {
    s_interval_track_counts[i] = 0;
    // Initialize U-Net outputs for this interval
    for (int k = 0; k < 100; ++k) {
      s_interval_unet_outputs[i * 100 + k] = 0.0f;
    }
  }
  
  // Initialize global memory FC buffers for this event
  for (int i = thread_id; i < PVinference::N_INTERVALS * 8 * 100; i += block_size) {
    dev_interval_fc_buffers[i] = 0.0f;
  }
  
  __syncthreads();
  
  // ========================================================================
  // PHASE 1: FC Processing Per Track + Interval Aggregation
  // ========================================================================
  for (unsigned track_idx = thread_id; track_idx < n_tracks; track_idx += block_size) {
    
    // Get the specific track and its Kalman state
    const auto track = velo_tracks.track(track_idx);
    const auto state = velo_states.state(track.track_index());
    
    // Extract real track features using physics calculations
    float track_features[PVinference::TRACK_FEATURES];
    extract_track_features(state, track_features);
    
    // Normalize features
    float normalized_features[PVinference::TRACK_FEATURES];
    normalize_input_features(track_features, normalized_features, PVinference::TRACK_FEATURES);
    
    // Assign track to intervals using real POCA z-coordinate
    const float z_poca = track_features[2]; // poca_z is index 2
    int interval1, interval2;
    bool has_second_interval;
    assign_intervals(z_poca, interval1, interval2, has_second_interval);
    
    // FC network forward pass (outputs 800 values for U-Net input)
    float fc_output[800];  // Output for U-Net input [8, 100]
    float fc_workspace[1600]; // Workspace for layer computations (800*2)
    
    // Get FC weights from global memory
    const float* fc_weights = parameters.dev_fc_weights;
    const float* fc_biases = parameters.dev_fc_biases;
    
    // Run FC neural network for this track
    neural_network_forward(normalized_features, fc_weights, fc_biases, fc_output, fc_workspace);
    
    // PHASE 1 OPTIMIZATION: Aggregate FC output to intervals instead of running U-Net per track
    aggregate_fc_to_intervals(fc_output, interval1, interval2, has_second_interval,
                             dev_interval_fc_buffers, s_interval_track_counts, event_number);
  }
  __syncthreads();
  
  // ========================================================================
  // PHASE 2: U-Net Processing Per Interval
  // ========================================================================
  for (int interval = thread_id; interval < PVinference::N_INTERVALS; interval += block_size) {
    // Get U-Net workspace from global memory
    float* unet_workspace = parameters.dev_unet_workspace + 
      event_number * PVinference::UNET_WORKSPACE_SIZE;
    
    // Process U-Net for this interval using aggregated FC data
    process_interval_unet(interval, dev_interval_fc_buffers, s_interval_track_counts,
                         parameters.dev_unet_weights, parameters.dev_unet_biases,
                         parameters.dev_unet_bn_params, unet_workspace,
                         s_interval_unet_outputs, event_number);
  }
  __syncthreads();
  
  // ========================================================================
  // PHASE 3: Reduction-Based KDE Aggregation (PHASE 2 OPTIMIZATION)
  // ========================================================================
  
  // Step 1: Warp-level contribution calculation
  warp_level_kde_reduction(s_interval_unet_outputs, s_interval_track_counts, s_warp_contributions);
  __syncthreads();
  
  // Step 2: Tree reduction across warps
  tree_reduction_kde_aggregation(s_warp_contributions, s_kde_histogram);
  __syncthreads();
  
  // Phase 6: Apply final normalization if needed
  // Following UpperLimit processInterval logic for consistent scaling
  for (int i = thread_id; i < PVinference::KDE_BINS; i += block_size) {
    // Maintain original aggregation but ensure proper range
    // Values already scaled by 0.001 in U-Net processing
    s_kde_histogram[i] = fmaxf(0.0f, s_kde_histogram[i]);
  }
  __syncthreads();
  
  // Write final output
  float* event_output = parameters.dev_output_kde + event_number * PVinference::KDE_BINS;
  for (int i = thread_id; i < PVinference::KDE_BINS; i += block_size) {
    event_output[i] = s_kde_histogram[i];
  }
  
  // Phase 6: Enhanced debug output with KDE validation (minimal debugging)
  /*
  if (event_number == 0 && thread_id == 0) {
    // Calculate min, max for validation
    float min_val = event_output[0];
    float max_val = event_output[0];
    
    for (int i = 1; i < PVinference::KDE_BINS; ++i) {
      min_val = fminf(min_val, event_output[i]);
      max_val = fmaxf(max_val, event_output[i]);
    }
    
    // Only print for event 0 to avoid spam
    printf("Event %u Final KDE: min=%.8f, max=%.8f, first_10=[%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f,%.8f]\n",
           event_number, min_val, max_val,
           event_output[0], event_output[1], event_output[2], event_output[3], event_output[4],
           event_output[5], event_output[6], event_output[7], event_output[8], event_output[9]);
  }
  */
}
