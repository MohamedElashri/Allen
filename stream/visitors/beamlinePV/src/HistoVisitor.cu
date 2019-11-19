#include "SequenceVisitor.cuh"
#include "pv_beamline_histo.cuh"
#include "pv_beamline_monitoring.h"

template<>
void SequenceVisitor::set_arguments_size<pv_beamline_histo_t>(
  const pv_beamline_histo_t& state,
  pv_beamline_histo_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  // Set arguments size
  arguments.set_size<dev_zhisto>(host_buffers.host_number_of_selected_events[0] * (zmax - zmin) / dz);
}

template<>
void SequenceVisitor::visit<pv_beamline_histo_t>(
  pv_beamline_histo_t& state,
  const pv_beamline_histo_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_atomics_velo>(),
    arguments.offset<dev_velo_track_hit_number>(),
    arguments.offset<dev_pvtracks>(),
    arguments.offset<dev_zhisto>(),
    constants.dev_beamline.data());

  state.invoke();

  // debugging

  //   // Retrieve result
  // cudaCheck(cudaMemcpyAsync(
  //   host_buffers.host_zhisto,
  //   arguments.offset<dev_zhisto>(),
  //   arguments.size<dev_zhisto>(),
  //   cudaMemcpyDeviceToHost,
  //   cuda_stream
  // ));

  // // Wait to receive the result
  // cudaEventRecord(cuda_generic_event, cuda_stream);
  // cudaEventSynchronize(cuda_generic_event);

  // pv_beamline_monitor(host_buffers.host_number_of_selected_events[0], host_buffers.host_zhisto);
}
