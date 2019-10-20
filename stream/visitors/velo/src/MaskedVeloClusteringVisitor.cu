#include "SequenceVisitor.cuh"
#include "MaskedVeloClustering.cuh"

template<>
void SequenceVisitor::set_arguments_size<velo_masked_clustering_t>(
  velo_masked_clustering_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_velo_cluster_container>(6 * host_buffers.host_total_number_of_velo_clusters[0]);
}

template<>
void SequenceVisitor::visit<velo_masked_clustering_t>(
  velo_masked_clustering_t& state,
  const velo_masked_clustering_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  state.set_opts(runtime_options.mep_layout, dim3(host_buffers.host_number_of_selected_events[0]), dim3(256), cuda_stream);
  state.set_arguments(
    runtime_options.mep_layout,
    arguments.offset<dev_velo_raw_input>(),
    arguments.offset<dev_velo_raw_input_offsets>(),
    arguments.offset<dev_estimated_input_size>(),
    arguments.offset<dev_module_cluster_num>(),
    arguments.offset<dev_module_candidate_num>(),
    arguments.offset<dev_cluster_candidates>(),
    arguments.offset<dev_velo_cluster_container>(),
    arguments.offset<dev_event_list>(),
    constants.dev_velo_geometry,
    constants.dev_velo_sp_patterns.data(),
    constants.dev_velo_sp_fx.data(),
    constants.dev_velo_sp_fy.data());

  state.invoke(runtime_options.mep_layout);

  // std::vector<uint> estimated_input_size (arguments.size<dev_estimated_input_size>() >> 2);
  // std::vector<uint> module_cluster_num (arguments.size<dev_module_cluster_num>() >> 2);

  // cudaCheck(cudaMemcpy(estimated_input_size.data(),
  //   arguments.offset<dev_estimated_input_size>(),
  //   arguments.size<dev_estimated_input_size>(),
  //   cudaMemcpyDeviceToHost));

  // cudaCheck(cudaMemcpy(module_cluster_num.data(),
  //   arguments.offset<dev_module_cluster_num>(),
  //   arguments.size<dev_module_cluster_num>(),
  //   cudaMemcpyDeviceToHost));

  // for (int i=0; i<estimated_input_size.size() - 1; ++i) {
  //   const auto estimated_module_size = estimated_input_size[i+1] - estimated_input_size[i];
  //   const auto module_size = module_cluster_num[i];

  //   if (module_size > estimated_module_size) {
  //     warning_cout << "Module size exceeds estimated size for event "
  //       << (i / 52) << ", module " << (i % 52) << " \n";
  //   }
  // }
}
