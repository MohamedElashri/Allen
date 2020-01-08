#include "GlobalEventCut.cuh"

void global_event_cut_t::set_arguments_size(
  ArgumentRefManager<Arguments> arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers) const
{
  // Note: The GEC on the GPU needs UT and SciFi data
  arguments.set_size<dev_ut_raw_input>(std::get<0>(runtime_options.host_ut_events).size_bytes());
  arguments.set_size<dev_ut_raw_input_offsets>(std::get<1>(runtime_options.host_ut_events).size_bytes());
  arguments.set_size<dev_scifi_raw_input>(std::get<0>(runtime_options.host_scifi_events).size_bytes());
  arguments.set_size<dev_scifi_raw_input_offsets>(std::get<1>(runtime_options.host_scifi_events).size_bytes());
}

void global_event_cut_t::operator()(
  const ArgumentRefManager<Arguments>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event) const
{
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

  cudaCheck(cudaMemsetAsync(arguments.offset<dev_number_of_selected_events>(), 0, sizeof(uint), cuda_stream));

  function(dim3(runtime_options.number_of_events), block_dimension(), cuda_stream)(
    arguments.offset<dev_ut_raw_input>(),
    arguments.offset<dev_ut_raw_input_offsets>(),
    arguments.offset<dev_scifi_raw_input>(),
    arguments.offset<dev_scifi_raw_input_offsets>(),
    arguments.offset<dev_number_of_selected_events>(),
    arguments.offset<dev_event_list>());

  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_number_of_selected_events,
    arguments.offset<dev_number_of_selected_events>(),
    sizeof(uint),
    cudaMemcpyDeviceToHost,
    cuda_stream));

  cudaCheck(cudaMemcpyAsync(
    host_buffers.host_event_list,
    arguments.offset<dev_event_list>(),
    runtime_options.number_of_events * sizeof(uint),
    cudaMemcpyHostToDevice,
    cuda_stream));

  cudaEventRecord(cuda_generic_event, cuda_stream);
  cudaEventSynchronize(cuda_generic_event);
}

__global__ void global_event_cut(
  char* ut_raw_input,
  uint* ut_raw_input_offsets,
  char* scifi_raw_input,
  uint* scifi_raw_input_offsets,
  uint* number_of_selected_events,
  uint* event_list)
{
  const uint event_number = blockIdx.x;

  // Check SciFi clusters
  const SciFi::SciFiRawEvent scifi_event(scifi_raw_input + scifi_raw_input_offsets[event_number]);
  __shared__ uint n_SciFi_clusters;
  if (threadIdx.x == 0) n_SciFi_clusters = 0;
  __syncthreads();
  for (uint i = threadIdx.x; i < scifi_event.number_of_raw_banks; i += blockDim.x) {
    // get bank size in bytes, subtract four bytes for header word
    uint bank_size = scifi_event.raw_bank_offset[i + 1] - scifi_event.raw_bank_offset[i] - 4;
    atomicAdd(&n_SciFi_clusters, bank_size);
  }
  __syncthreads();
  // Bank size is given in bytes. There are 2 bytes per cluster.
  // 4 bytes are removed for the header.
  // Note that this overestimates slightly the number of clusters
  // due to bank padding in 32b. For v5, it further overestimates the
  // number of clusters due to the merging of clusters.
  if (threadIdx.x == 0) n_SciFi_clusters = n_SciFi_clusters / 2 - 2;
  __syncthreads();

  // Check UT clusters
  const uint32_t ut_event_offset = ut_raw_input_offsets[event_number];
  const UTRawEvent ut_event(ut_raw_input + ut_event_offset);
  __shared__ uint n_UT_clusters;
  if (threadIdx.x == 0) n_UT_clusters = 0;
  __syncthreads();
  for (uint i = threadIdx.x; i < ut_event.number_of_raw_banks; i += blockDim.x) {
    const UTRawBank ut_bank = ut_event.getUTRawBank(i);
    atomicAdd(&n_UT_clusters, ut_bank.number_of_hits);
  }
  __syncthreads();

  const auto num_combined_clusters = n_UT_clusters + n_SciFi_clusters;

  if (num_combined_clusters >= max_scifi_ut_clusters) return;

  // passed cut
  if (threadIdx.x == 0) {
    const int selected_event = atomicAdd(number_of_selected_events, 1);
    event_list[selected_event] = event_number;
  }
}
