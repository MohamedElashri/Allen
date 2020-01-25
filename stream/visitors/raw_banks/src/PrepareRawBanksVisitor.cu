#include "PrepareRawBanks.cuh"
#include "SequenceVisitor.cuh"

template<>
void SequenceVisitor::set_arguments_size<prepare_raw_banks_t>(
  const prepare_raw_banks_t& state,
  prepare_raw_banks_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  int n_hlt1_lines = Hlt1::Hlt1Lines::End;
  arguments.set_size<dev_dec_reports>((2 + n_hlt1_lines) * host_buffers.host_number_of_selected_events[0]);
  arguments.set_size<dev_number_of_passing_events>(1);
  arguments.set_size<dev_passing_event_list>(host_buffers.host_number_of_selected_events[0]);
}

template<>
void SequenceVisitor::visit<prepare_raw_banks_t>(
  prepare_raw_banks_t& state,
  const prepare_raw_banks_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  // Initialize number of events passing Hlt1.
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_number_of_passing_events>(),
    0,
    sizeof(uint),
    cuda_stream));
  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_dec_reports>(),
    0,
    arguments.size<dev_dec_reports>(),
    cuda_stream));
  
  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), dim3(256), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_atomics_scifi>(),
    arguments.offset<dev_sv_atomics>(),
    arguments.offset<dev_sel_results>(),
    arguments.offset<dev_sel_results_atomics>(),
    arguments.offset<dev_dec_reports>(),
    arguments.offset<dev_number_of_passing_events>(),
    arguments.offset<dev_passing_event_list>());
  state.invoke();
  
  // Copy raw bank data.
  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_dec_reports,
    arguments.offset<dev_dec_reports>(),
    arguments.size<dev_dec_reports>(),
    cudaMemcpyDeviceToHost,
    cuda_stream));

  // Copy list of passing events.
  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_number_of_passing_events,
    arguments.offset<dev_number_of_passing_events>(),
    arguments.size<dev_number_of_passing_events>(),
    cudaMemcpyDeviceToHost,
    cuda_stream));
  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_passing_event_list,
    arguments.offset<dev_passing_event_list>(),
    arguments.size<dev_passing_event_list>(),
    cudaMemcpyDeviceToHost,
    cuda_stream));
}
