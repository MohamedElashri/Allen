#include "CalculatePhiAndSort.cuh"

void velo_calculate_phi_and_sort_t::set_arguments_size(
  ArgumentRefManager<Arguments> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  arguments.set_size<dev_hit_permutation>(host_buffers.host_total_number_of_velo_clusters[0]);
}

void velo_calculate_phi_and_sort_t::operator()(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  function.invoke(dim3(host_buffers.host_number_of_selected_events[0]), block_dimension(), cuda_stream)(
    arguments.offset<dev_estimated_input_size>(),
    arguments.offset<dev_module_cluster_num>(),
    arguments.offset<dev_velo_cluster_container>(),
    arguments.offset<dev_hit_permutation>());
}

/**
 * @brief Track forwarding algorithm based on triplet finding
 */
__global__ void velo_calculate_phi_and_sort(
  uint* dev_module_cluster_start,
  uint* dev_module_cluster_num,
  uint32_t* dev_velo_cluster_container,
  uint* dev_hit_permutations)
{
  __shared__ float shared_hit_phis[Velo::Constants::max_numhits_in_module];

  /* Data initialization */
  // Each event is treated with two blocks, one for each side.
  const uint event_number = blockIdx.x;
  const uint number_of_events = gridDim.x;

  // Pointers to data within the event
  const uint number_of_hits = dev_module_cluster_start[Velo::Constants::n_modules * number_of_events];
  const uint* module_hitStarts = dev_module_cluster_start + event_number * Velo::Constants::n_modules;
  const uint* module_hitNums = dev_module_cluster_num + event_number * Velo::Constants::n_modules;

  float* hit_Xs = (float*) (dev_velo_cluster_container);
  float* hit_Ys = (float*) (dev_velo_cluster_container + number_of_hits);
  float* hit_Zs = (float*) (dev_velo_cluster_container + 2 * number_of_hits);
  uint32_t* hit_IDs = (uint32_t*) (dev_velo_cluster_container + 3 * number_of_hits);
  float* hit_Phis = (float*) (dev_velo_cluster_container + 4 * number_of_hits);
  int32_t* hit_temp = (int32_t*) (dev_velo_cluster_container + 5 * number_of_hits);

  uint* hit_permutations = dev_hit_permutations;

  // TODO: Check speed of various options
  // Initialize hit_permutations to zero
  const uint event_hit_start = module_hitStarts[0];
  const uint event_number_of_hits = module_hitStarts[Velo::Constants::n_modules] - event_hit_start;
  for (unsigned int i = 0; i < (event_number_of_hits + blockDim.x - 1) / blockDim.x; ++i) {
    const auto index = i * blockDim.x + threadIdx.x;
    if (index < event_number_of_hits) {
      hit_permutations[event_hit_start + index] = 0;
    }
  }

  __syncthreads();

  // Calculate phi and populate hit_permutations
  calculate_phi(module_hitStarts, module_hitNums, hit_Xs, hit_Ys, hit_Phis, hit_permutations, shared_hit_phis);

  // Due to phi RAW
  __syncthreads();

  // Sort by phi
  sort_by_phi(event_hit_start, event_number_of_hits, hit_Xs, hit_Ys, hit_Zs, hit_IDs, hit_temp, hit_permutations);
}
