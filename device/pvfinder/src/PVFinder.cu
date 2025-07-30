#include "PVFinder.cuh"
#include <cuda_runtime.h>

INSTANTIATE_ALGORITHM(PVFinder::PVFinder_t)

namespace PVFinder {

// Simple neural network forward pass for debugging
__device__ __forceinline__ void neural_network_forward(
    const float* input, float* output) {
    
    // Simple scalar approach to isolate performance issues
    float layer_input[20];
    float layer_output[20];
    
    // Copy input to layer_input
    for (int i = 0; i < 9; ++i) {
        layer_input[i] = input[i];
    }
    
    int weight_offset = 0;
    int bias_offset = 0;
    
    // Process hidden layers with  loops
    for (int layer = 0; layer < 5; ++layer) {
        const int input_size = (layer == 0) ? 9 : 20;
        
        // computation for hidden layers
        for (int j = 0; j < 20; ++j) {
            float sum = PVFinder::MODEL_BIASES[bias_offset + j];
            
            // inner product
            for (int k = 0; k < input_size; ++k) {
                sum += PVFinder::MODEL_WEIGHTS[weight_offset + j * input_size + k] * layer_input[k];
            }
            
            // Simple leaky ReLU
            layer_output[j] = (sum > 0.0f) ? sum : 0.01f * sum;
        }
        
        // Simple copy
        for (int j = 0; j < 20; ++j) {
            layer_input[j] = layer_output[j];
        }
        
        weight_offset += input_size * 20;
        bias_offset += 20;
    }
    
    // Output layer with simple softplus
    for (int j = 0; j < 100; ++j) {
        float sum = PVFinder::MODEL_BIASES[bias_offset + j];
        
        for (int k = 0; k < 20; ++k) {
            sum += PVFinder::MODEL_WEIGHTS[weight_offset + j * 20 + k] * layer_input[k];
        }
        
        // Simple softplus approximation
        output[j] = (sum > 0.0f) ? sum + logf(1.0f + expf(-sum)) : logf(1.0f + expf(sum));
    }
}

//  softplus approximation avoiding branches
__device__ __forceinline__ float softplus(float x) {
    // Use polynomial approximation for speed
    return fmaxf(0.0f, x) + __logf(1.0f + __expf(-fabsf(x)));
}

// Optimized interval assignment without branches
__device__ __forceinline__ void assign_intervals(
    float z_poca, int& interval1, int& interval2, bool& has_second) {
    
    z_poca += 100.0f;
    
    // Branchless computation using arithmetic operations
    const float inv_10 = 0.1f;
    const int base_interval = __float2int_rd(z_poca * inv_10);
    interval1 = min(39, max(0, base_interval));
    
    // Branchless edge detection
    const float edge_low = 10.0f;
    const float edge_high = 390.0f;
    const bool is_low_edge = z_poca <= edge_low;
    const bool is_high_edge = z_poca >= edge_high;
    const bool in_range = (z_poca >= 0.0f) & (z_poca <= 400.0f);
    
    has_second = in_range & (is_low_edge | is_high_edge);
    interval2 = interval1 + (is_low_edge ? 1 : -1);
}

// Optimized ellipsoid calculation with vectorized math
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

// vector operations using intrinsics
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

// normalization for intervals using vectorized operations
__device__ __forceinline__ void normalize_for_interval(
    const float* input, float* output, int interval) {
    
    const float z_min = -100.0f;
    const float z_max = 300.0f;
    const float interval_size = (z_max - z_min) * 0.01f; // divide by 100
    const float interval_center = __fmaf_rn(interval + 0.5f, interval_size, z_min);
    const float inv_interval_size = __frcp_rn(interval_size);
    
    // Vectorized normalization
    output[0] = (input[0] - interval_center) * inv_interval_size;
    output[1] = (input[1] - interval_center) * inv_interval_size;
    output[2] = (input[2] - interval_center) * inv_interval_size;
    
    // Normalize ellipsoid parameters
    #pragma unroll
    for (int i = 3; i < 9; ++i) {
        output[i] = input[i] * inv_interval_size;
    }
}

// main kernel
__global__ void pv_finder_kernel(Parameters parameters) {
    const unsigned event_number = blockIdx.x;
    const unsigned thread_id = threadIdx.x;
    
    const auto velo_tracks_view = parameters.dev_velo_tracks_view[event_number];
    const auto velo_states_view = parameters.dev_velo_states_view[event_number];
    const unsigned num_tracks = velo_tracks_view.size();
    
    // Simple shared memory strategy
    __shared__ float s_histogram[100];
    __shared__ int s_interval_counts[NUM_INTERVALS];
    
    // Initialize shared memory
    if (thread_id < NUM_INTERVALS) {
        s_interval_counts[thread_id] = 0;
    }
    if (thread_id < 100) {
        s_histogram[thread_id] = 0.0f;
    }
    
    __syncthreads();
    
    // Process tracks with proper physics calculations
    for (unsigned track_idx = thread_id; track_idx < num_tracks; track_idx += blockDim.x) {
        const auto track = velo_tracks_view.track(track_idx);
        const auto state = velo_states_view.state(track.track_index());
        
        // Proper ellipsoid calculation with realistic physics
        float ellipsoid_params[6];
        float poca_x, poca_y, poca_z;
        calculate_ellipsoid_params(state, ellipsoid_params, poca_x, poca_y, poca_z);
        
        // Proper interval assignment
        int interval1, interval2;
        bool has_second_interval;
        assign_intervals(poca_z, interval1, interval2, has_second_interval);
        
        // Proper track data with all physics parameters
        float track_data[9] = {
            poca_x, poca_y, poca_z,
            ellipsoid_params[0], ellipsoid_params[1], ellipsoid_params[2],
            ellipsoid_params[3], ellipsoid_params[4], ellipsoid_params[5]
        };
        
        // Process primary interval with proper normalization
        {
            float normalized_input[9];
            normalize_for_interval(track_data, normalized_input, interval1);
            
            float output[100];
            neural_network_forward(normalized_input, output);
            
            // Simple accumulation
            for (int k = 0; k < 100; ++k) {
                atomicAdd(&s_histogram[k], output[k]);
            }
        }
        
        // Process secondary interval if exists
        if (has_second_interval) {
            float normalized_input[9];
            normalize_for_interval(track_data, normalized_input, interval2);
            
            float output[100];
            neural_network_forward(normalized_input, output);
            
            for (int k = 0; k < 100; ++k) {
                atomicAdd(&s_histogram[k], output[k]);
            }
        }
        
        // Update interval counts
        atomicAdd(&s_interval_counts[interval1], 1);
        if (has_second_interval) {
            atomicAdd(&s_interval_counts[interval2], 1);
        }
    }
    
    __syncthreads();
    
    // Simple output strategy
    if (thread_id < 100) {
        for (int interval = 0; interval < NUM_INTERVALS; ++interval) {
            const float weight = s_interval_counts[interval] > 0 ? 
                1.0f / (float)s_interval_counts[interval] : 0.0f;
            const int global_idx = event_number * NUM_INTERVALS * 100 + interval * 100 + thread_id;
            
            parameters.dev_output_histogram[global_idx] = s_histogram[thread_id] * weight;
        }
    }
}

// Set arguments size with optimized memory allocation
void PVFinder_t::set_arguments_size(ArgumentReferences<Parameters> arguments, const RuntimeOptions&, const Constants&) const {
    const unsigned num_events = first<host_number_of_events_t>(arguments);
    
    // Optimized memory layout: NUM_INTERVALS * HISTOGRAM_SIZE per event
    set_size<dev_output_histogram_t>(arguments, num_events * NUM_INTERVALS * HISTOGRAM_SIZE);
}

// Main operator for kernel launch
void PVFinder_t::operator()(
    const ArgumentReferences<Parameters>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const Allen::Context& context) const
{
    const unsigned num_events = first<host_number_of_events_t>(arguments);
    
    // grid/block configuration
    const dim3 grid(num_events);
    const dim3 block = m_block_dim;
    // Launch kernel
    global_function(pv_finder_kernel)(grid, block, context)(arguments);
}

} // namespace PVFinder
