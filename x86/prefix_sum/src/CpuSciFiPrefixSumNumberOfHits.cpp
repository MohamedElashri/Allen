#include "CpuSciFiPrefixSumNumberOfHits.h"

void cpu_scifi_prefix_sum_number_of_hits_t::operator()(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  cpu_prefix_sum(
    host_buffers.host_prefix_sum_buffer,
    host_buffers.host_allocated_prefix_sum_space,
    arguments.offset<dev_scifi_hit_count>(),
    arguments.size<dev_scifi_hit_count>(),
    cuda_stream,
    cuda_generic_event,
    host_buffers.host_accumulated_number_of_scifi_hits);
}
