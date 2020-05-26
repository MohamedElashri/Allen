#include "TrackMVALineAlgorithm.cuh"

void track_mva_line_algorithm::track_mva_line_algorithm_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<decisions_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
}

void track_mva_line_algorithm::track_mva_line_algorithm_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  HostBuffers& host_buffers,
  cudaStream_t& stream,
  cudaEvent_t&) const
{
  initialize<decisions_t>(arguments, 0, stream);

  std::vector<decisions_t::type> a;

  // print<decisions_t>(arguments);

  global_function(onetrackline<decltype(*this), Parameters>)(
    first<host_number_of_selected_events_t>(arguments),
    dim3(property<block_dim_x_t>()),
    stream
  )(
    data<dev_kf_tracks_t>(arguments), data<dev_track_offsets_t>(arguments), *this, arguments,
    decisions);

  // print<decisions_t>(arguments);
}
