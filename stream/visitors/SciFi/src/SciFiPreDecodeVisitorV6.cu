#include "SequenceVisitor.cuh"
#include "SciFiPreDecodeV6.cuh"

template<>
void SequenceVisitor::set_arguments_size<scifi_pre_decode_v6_t>(
  scifi_pre_decode_v6_t& state,
  scifi_pre_decode_v6_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_scifi_hits>(host_buffers.scifi_hits_uints());
}

template<>
void SequenceVisitor::visit<scifi_pre_decode_v6_t>(
  scifi_pre_decode_v6_t& state,
  const scifi_pre_decode_v6_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  state.set_opts(
    dim3(host_buffers.host_number_of_selected_events[0]), dim3(SciFi::SciFiRawBankParams::NbBanks), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_scifi_raw_input>(),
    arguments.offset<dev_scifi_raw_input_offsets>(),
    arguments.offset<dev_event_list>(),
    arguments.offset<dev_scifi_hit_count>(),
    arguments.offset<dev_scifi_hits>(),
    constants.dev_scifi_geometry,
    constants.dev_inv_clus_res);

  state.invoke();

  // Debugging
  /*const uint hit_count_uints = 2 * host_buffers.host_number_of_selected_events[0] * SciFi::Constants::n_mats + 1;
  uint host_scifi_hit_count[hit_count_uints];
  uint* host_scifi_hits = new uint[host_buffers.scifi_hits_uints()];
  cudaCheck(cudaMemcpyAsync(&host_scifi_hit_count, arguments.offset<dev_scifi_hit_count>(),
  hit_count_uints*sizeof(uint), cudaMemcpyDeviceToHost, cuda_stream)); cudaCheck(cudaMemcpyAsync(host_scifi_hits,
  arguments.offset<dev_scifi_hits>(), arguments.size<dev_scifi_hits>(), cudaMemcpyDeviceToHost, cuda_stream));
  cudaEventRecord(cuda_generic_event, cuda_stream);
  cudaEventSynchronize(cuda_generic_event);
  SciFi::SciFiGeometry host_geom(constants.host_scifi_geometry);
  SciFi::Hits hi(host_scifi_hits, host_scifi_hit_count[host_buffers.host_number_of_selected_events[0] *
  SciFi::Constants::n_mat_groups_and_mats], &host_geom, constants.host_inv_clus_res.data()); std::ofstream
  outfile("dump_predecode_v6.txt");

  for(size_t event = 0; event < host_buffers.host_number_of_selected_events[0]; event++) {
    SciFi::HitCount host_scifi_hit_count_struct(host_scifi_hit_count, event);
    for(size_t zone = 0; zone < SciFi::Constants::n_zones; zone++) {
      outfile << "\n\nZone " << zone << ": ";
      for(size_t hit = 0; hit < host_scifi_hit_count_struct.zone_number_of_hits(zone); hit++) {
        uint h = host_scifi_hit_count_struct.zone_offset(zone) + hit;
        outfile << (hi.cluster_reference[h]) << " ";
      }
    }
  }
  outfile << std::endl;*/
}
