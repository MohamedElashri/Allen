/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "MatchingCopyTrackHitNumber.cuh"

INSTANTIATE_ALGORITHM(matching_copy_track_hit_number::matching_copy_track_hit_number_t);

void matching_copy_track_hit_number::matching_copy_track_hit_number_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_matched_track_hit_number_t>(arguments, first<host_number_of_reconstructed_matched_tracks_t>(arguments));
}

void matching_copy_track_hit_number::matching_copy_track_hit_number_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  global_function(matching_copy_track_hit_number)(
    dim3(first<host_number_of_events_t>(arguments)), property<block_dim_t>(), context)(arguments);
}

/**
 * @brief Copies UT track hit numbers on a consecutive container
 */
__global__ void matching_copy_track_hit_number::matching_copy_track_hit_number(
  matching_copy_track_hit_number::Parameters parameters)
{
  // const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const auto event_number = blockIdx.x;
  const auto event_tracks = parameters.dev_matched_tracks + event_number * TrackMatchingConsts::max_num_tracks;
  const auto accumulated_tracks = parameters.dev_atomics_matched[event_number];
  const auto number_of_tracks =
    parameters.dev_atomics_matched[event_number + 1] - parameters.dev_atomics_matched[event_number];

  // Pointer to ut_track_hit_number of current event.
  unsigned* matched_track_hit_number = parameters.dev_matched_track_hit_number + accumulated_tracks;

  // debug_cout << "in copy matched track hit number, event: " << event_number << "  number of tracks: " <<
  // number_of_tracks << std::endl;
  // Loop over tracks.
  for (unsigned element = threadIdx.x; element < number_of_tracks; element += blockDim.x) {
    matched_track_hit_number[element] = event_tracks[element].number_of_hits_velo +
                                        // event_tracks[element].number_of_hits_ut +
                                        event_tracks[element].number_of_hits_scifi;
  }
}
