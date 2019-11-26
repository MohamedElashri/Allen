#include "SequenceVisitor.cuh"
#include "pv_beamline_multi_fitter.cuh"

template<>
void SequenceVisitor::set_arguments_size<pv_beamline_multi_fitter_t>(
  const pv_beamline_multi_fitter_t& state,
  pv_beamline_multi_fitter_t::arguments_t arguments,
  const RuntimeOptions& runtime_options,
  const Constants& constants,
  const HostBuffers& host_buffers)
{
  // Set arguments size
  arguments.set_size<dev_multi_fit_vertices>(host_buffers.host_number_of_selected_events[0] * PV::max_number_vertices);
  arguments.set_size<dev_number_of_multi_fit_vertices>(host_buffers.host_number_of_selected_events[0]);
  arguments.set_size<dev_pvtracks_denom>(host_buffers.host_number_of_reconstructed_velo_tracks[0]);
}

template<>
void SequenceVisitor::visit<pv_beamline_multi_fitter_t>(
  pv_beamline_multi_fitter_t& state,
  const pv_beamline_multi_fitter_t::arguments_t& arguments,
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
    arguments.offset<dev_pvtracks_denom>(),
    arguments.offset<dev_zpeaks>(),
    arguments.offset<dev_number_of_zpeaks>(),
    arguments.offset<dev_multi_fit_vertices>(),
    arguments.offset<dev_number_of_multi_fit_vertices>(),
    constants.dev_beamline.data(),
    arguments.offset<dev_pvtrack_z>());

  cudaCheck(cudaMemsetAsync(
    arguments.offset<dev_number_of_multi_fit_vertices>(),
    0,
    arguments.size<dev_number_of_multi_fit_vertices>(),
    cuda_stream));

  state.invoke();
}
