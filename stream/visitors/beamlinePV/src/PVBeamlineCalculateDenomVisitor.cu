#include "SequenceVisitor.cuh"
#include "pv_beamline_calculate_denom.cuh"

template<>
void SequenceVisitor::set_arguments_size<pv_beamline_calculate_denom_t>(
  pv_beamline_calculate_denom_t& state,
  pv_beamline_calculate_denom_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  arguments.set_size<dev_pvtracks_denom>(host_buffers.host_number_of_reconstructed_velo_tracks[0]);
}

template<>
void SequenceVisitor::visit<pv_beamline_calculate_denom_t>(
  pv_beamline_calculate_denom_t& state,
  const pv_beamline_calculate_denom_t::arguments_t& arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  HostBuffers& host_buffers,
  cudaStream_t& cuda_stream,
  cudaEvent_t& cuda_generic_event)
{
  state.set_opts(dim3(host_buffers.host_number_of_selected_events[0]), dim3(256), cuda_stream);
  state.set_arguments(
    arguments.offset<dev_atomics_velo>(),
    arguments.offset<dev_velo_track_hit_number>(),
    arguments.offset<dev_pvtracks>(),
    arguments.offset<dev_pvtracks_denom>(),
    arguments.offset<dev_zpeaks>(),
    arguments.offset<dev_number_of_zpeaks>());

  state.invoke();
}
