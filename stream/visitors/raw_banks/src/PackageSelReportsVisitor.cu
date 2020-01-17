#include "PackageSelReports.cuh"
#include "SequenceVisitor.cuh"
#include "HltSelReport.cuh"

template<>
void SequenceVisitor::set_arguments_size<package_sel_reps_t>(
  const package_sel_reps_t& state,
  package_sel_reps_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_sel_rep_raw_banks>(host_buffers.host_number_of_sel_rep_words[0]);
}

template<>
void SequenceVisitor::visit<package_sel_reps_t>(
  package_sel_reps_t& state,
  const package_sel_reps_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_sel_rep_raw_banks>(),
    0,
    arguments.size<dev_sel_rep_raw_banks>(),
    cuda_stream));
  
  state.set_opts(dim3(host_buffers.host_number_of_passing_events[0]), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_atomics_scifi>(),
    arguments.offset<dev_sel_rb_hits>(),
    arguments.offset<dev_sel_rb_stdinfo>(),
    arguments.offset<dev_sel_rb_objtyp>(),
    arguments.offset<dev_sel_rb_substr>(),
    arguments.offset<dev_sel_rep_raw_banks>(),
    arguments.offset<dev_sel_rep_offsets>(),
    arguments.offset<dev_passing_event_list>(),
    host_buffers.host_number_of_selected_events[0]);
  state.invoke();

  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_sel_rep_offsets,
    arguments.offset<dev_sel_rep_offsets>(),
    arguments.size<dev_sel_rep_offsets>(),
    cudaMemcpyDeviceToHost,
    cuda_stream));
  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_sel_rep_raw_banks,
    arguments.offset<dev_sel_rep_raw_banks>(),
    arguments.size<dev_sel_rep_raw_banks>(),
    cudaMemcpyDeviceToHost,
    cuda_stream));
  
  cudaEventRecord(cuda_generic_event, cuda_stream);
  cudaEventSynchronize(cuda_generic_event);

}