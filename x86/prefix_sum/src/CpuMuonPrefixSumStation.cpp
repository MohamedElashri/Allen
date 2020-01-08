#include "CpuMuonPrefixSumStation.h"

void cpu_muon_prefix_sum_station_t::operator()(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
  function(
    host_buffers.host_prefix_sum_buffer,
    host_buffers.host_allocated_prefix_sum_space,
    offset<dev_station_ocurrences_offset_t>(arguments),
    size<dev_station_ocurrences_offset_t>(arguments),
    cuda_stream,
    cuda_generic_event,
    host_buffers.host_muon_total_number_of_hits);
}
