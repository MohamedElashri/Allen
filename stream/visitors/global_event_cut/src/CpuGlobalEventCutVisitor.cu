#include "SequenceVisitor.cuh"
#include "CpuGlobalEventCut.cuh"

DEFINE_EMPTY_SET_ARGUMENTS_SIZE(cpu_global_event_cut_t)

template<>
void SequenceVisitor::visit<cpu_global_event_cut_t>(
  cpu_global_event_cut_t& state,
  const cpu_global_event_cut_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  state.invoke(
    std::get<0>(runtime_options.host_ut_events).begin(),
    std::get<1>(runtime_options.host_ut_events).begin(),
    std::get<0>(runtime_options.host_scifi_events).begin(),
    std::get<1>(runtime_options.host_scifi_events).begin(),
    host_buffers.host_number_of_selected_events,
    host_buffers.host_event_list,
    runtime_options.number_of_events);

  cudaCheck(cudaMemcpyAsync(
    arguments.offset<dev_event_list>(),
    host_buffers.host_event_list,
    runtime_options.number_of_events * sizeof(uint),
    cudaMemcpyHostToDevice,
    cuda_stream));

  if (logger::ll.verbosityLevel >= logger::debug) {
    debug_cout << "Selected " << host_buffers.host_number_of_selected_events[0] << " / "
               << runtime_options.number_of_events << " events with global event cuts" << std::endl;
  }
}
