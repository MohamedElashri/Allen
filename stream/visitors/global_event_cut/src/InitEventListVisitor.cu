#include "SequenceVisitor.cuh"
#include "InitEventList.cuh"

template<>
void SequenceVisitor::set_arguments_size<init_event_list_t>(
  const init_event_list_t& state,
  init_event_list_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_velo_raw_input>(std::get<0>(runtime_options.host_velo_events).size_bytes());
  arguments.set_size<dev_velo_raw_input_offsets>(std::get<1>(runtime_options.host_velo_events).size_bytes());
  arguments.set_size<dev_ut_raw_input>(std::get<0>(runtime_options.host_ut_events).size_bytes());
  arguments.set_size<dev_ut_raw_input_offsets>(std::get<1>(runtime_options.host_ut_events).size_bytes());
  arguments.set_size<dev_scifi_raw_input>(std::get<0>(runtime_options.host_scifi_events).size_bytes());
  arguments.set_size<dev_scifi_raw_input_offsets>(std::get<1>(runtime_options.host_scifi_events).size_bytes());
  arguments.set_size<dev_event_list>(runtime_options.number_of_events);
  arguments.set_size<dev_number_of_selected_events>(1);
}

template<>
void SequenceVisitor::visit<init_event_list_t>(
  init_event_list_t& state,
  const init_event_list_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  // Fetch required arguments for the global event cuts algorithm and
  // the various decoding algorithms
  cudaCheck(cudaMemcpyAsync(
    arguments.offset<dev_velo_raw_input>(),
    std::get<0>(runtime_options.host_velo_events).begin(),
    std::get<0>(runtime_options.host_velo_events).size_bytes(),
    cudaMemcpyHostToDevice,
    cuda_stream));
  cudaCheck(cudaMemcpyAsync(
    arguments.offset<dev_velo_raw_input_offsets>(),
    std::get<1>(runtime_options.host_velo_events).begin(),
    std::get<1>(runtime_options.host_velo_events).size_bytes(),
    cudaMemcpyHostToDevice,
    cuda_stream));
  cudaCheck(cudaMemcpyAsync(
    arguments.offset<dev_ut_raw_input>(),
    std::get<0>(runtime_options.host_ut_events).begin(),
    std::get<0>(runtime_options.host_ut_events).size_bytes(),
    cudaMemcpyHostToDevice,
    cuda_stream));
  cudaCheck(cudaMemcpyAsync(
    arguments.offset<dev_ut_raw_input_offsets>(),
    std::get<1>(runtime_options.host_ut_events).begin(),
    std::get<1>(runtime_options.host_ut_events).size_bytes(),
    cudaMemcpyHostToDevice,
    cuda_stream));
  cudaCheck(cudaMemcpyAsync(
    arguments.offset<dev_scifi_raw_input>(),
    std::get<0>(runtime_options.host_scifi_events).begin(),
    std::get<0>(runtime_options.host_scifi_events).size_bytes(),
    cudaMemcpyHostToDevice,
    cuda_stream));
  cudaCheck(cudaMemcpyAsync(
    arguments.offset<dev_scifi_raw_input_offsets>(),
    std::get<1>(runtime_options.host_scifi_events).begin(),
    std::get<1>(runtime_options.host_scifi_events).size_bytes(),
    cudaMemcpyHostToDevice,
    cuda_stream));

  // Initialize buffers
  host_buffers.host_number_of_selected_events[0] = runtime_options.number_of_events;
  for (uint i = 0; i < runtime_options.number_of_events; ++i) {
    host_buffers.host_event_list[i] = i;
  }

  cudaCheck(cudaMemcpyAsync(
    arguments.offset<dev_event_list>(),
    host_buffers.host_event_list,
    runtime_options.number_of_events * sizeof(uint),
    cudaMemcpyHostToDevice,
    cuda_stream));
}
