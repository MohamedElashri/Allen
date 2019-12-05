#include "CpuVeloPrefixSumNumberOfHits.h"

void cpu_velo_prefix_sum_number_of_hits_t::visit(
    const ArgumentRefManager<Arguments>& arguments,
    const RuntimeOptions& runtime_options,
    const Constants& constants,
    HostBuffers& host_buffers,
    cudaStream_t& cuda_stream,
    cudaEvent_t& cuda_generic_event) const {
  // Invokes the function
  algorithm.invoke(
    host_buffers.host_prefix_sum_buffer,
    host_buffers.host_allocated_prefix_sum_space,
    arguments.offset<dev_velo_track_hit_number>(),
    arguments.size<dev_velo_track_hit_number>(),
    cuda_stream,
    cuda_generic_event,
    host_buffers.host_total_number_of_velo_clusters);
}
