#include "CpuPrefixSumVeloClusters.h"

void cpu_prefix_sum_velo_clusters_t::set_arguments_size(
    ArgumentRefManager<Arguments>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    const HostBuffers& host_buffers) const {}

void cpu_prefix_sum_velo_clusters_t::visit(
    const ArgumentRefManager<Arguments>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) {
  // Invokes the function
  function.invoke(
    host_buffers.host_prefix_sum_buffer,
    host_buffers.host_allocated_prefix_sum_space,
    arguments.offset<dev_estimated_input_size>(),
    arguments.size<dev_estimated_input_size>(),
    cuda_stream,
    cuda_generic_event,
    host_buffers.host_total_number_of_velo_clusters);
}
