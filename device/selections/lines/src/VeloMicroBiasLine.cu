#include "VeloMicroBiasLine.cuh"

// Explicit instantiation
INSTANTIATE_LINE(velo_micro_bias_line::velo_micro_bias_line_t, velo_micro_bias_line::Parameters)

__device__ std::tuple<const unsigned>
velo_micro_bias_line::velo_micro_bias_line_t::get_input(const Parameters& parameters, const unsigned event_number) const
{
  Velo::Consolidated::ConstTracks velo_tracks {
    parameters.dev_offsets_velo_tracks, parameters.dev_offsets_velo_track_hit_number, event_number, parameters.dev_number_of_events[0]};
  const unsigned number_of_velo_tracks = velo_tracks.number_of_tracks(event_number);
  return std::forward_as_tuple(number_of_velo_tracks);
}

__device__ bool velo_micro_bias_line::velo_micro_bias_line_t::select(
  const Parameters& parameters,
  std::tuple<const unsigned> input) const
{
  const auto number_of_velo_tracks = std::get<0>(input);
  return number_of_velo_tracks >= parameters.min_velo_tracks;
}
