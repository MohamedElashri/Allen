/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
*                                                                             *
* This software is distributed under the terms of the Apache License          *
* version 2 (Apache-2.0), copied verbatim in the file "LICENSE".              *
*                                                                             *
* In applying this licence, CERN does not waive the privileges and immunities *
* granted to it by virtue of its status as an Intergovernmental Organization  *
* or submit itself to any jurisdiction.                                       *
\*****************************************************************************/
#include "LFQualityFilterLength.cuh"

INSTANTIATE_ALGORITHM(lf_quality_filter_length::lf_quality_filter_length_t)

void lf_quality_filter_length::lf_quality_filter_length_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&) const
{
  set_size<dev_scifi_lf_length_filtered_tracks_t>(
    arguments,
    first<host_number_of_reconstructed_input_tracks_t>(arguments) * m_maximum_number_of_candidates_per_ut_track);
  set_size<dev_scifi_lf_length_filtered_atomics_t>(
    arguments, first<host_number_of_events_t>(arguments) * LookingForward::num_atomics);
  set_size<dev_scifi_lf_parametrization_length_filter_t>(
    arguments,
    4 * first<host_number_of_reconstructed_input_tracks_t>(arguments) * m_maximum_number_of_candidates_per_ut_track);
}

void lf_quality_filter_length::lf_quality_filter_length_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions&,
  const Constants&,
  const Allen::Context& context) const
{
  Allen::memset_async<dev_scifi_lf_length_filtered_atomics_t>(arguments, 0, context);

  global_function(lf_quality_filter_length)(dim3(size<dev_event_list_t>(arguments)), m_block_dim, context)(
    arguments,
    m_maximum_number_of_candidates_per_ut_track,
    m_min_tot_scifi_hits,
    m_min_UV_scifi_hits,
    m_min_X_scifi_hits);
}

template<bool with_ut, typename T>
__device__ void quality_filter_length(
  lf_quality_filter_length::Parameters parameters,
  const T* tracks,
  const unsigned maximum_number_of_candidates_per_ut_track,
  const unsigned min_tot_scifi_hits,
  const unsigned min_UV_scifi_hits,
  const unsigned min_X_scifi_hits)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  const auto input_tracks_view = tracks->container(event_number);
  const int event_tracks_offset = input_tracks_view.offset();
  // TODO: Don't do this. Will be replaced when SciFi EM is updated.
  const unsigned total_number_of_tracks =
    tracks->container(number_of_events - 1).offset() + tracks->container(number_of_events - 1).size();

  const auto number_of_tracks = parameters.dev_scifi_lf_atomics[event_number];

  for (unsigned i = threadIdx.x; i < number_of_tracks; i += blockDim.x) {
    const auto scifi_track_index = event_tracks_offset * maximum_number_of_candidates_per_ut_track + i;
    const SciFi::TrackHits& track = parameters.dev_scifi_lf_tracks[scifi_track_index];
    if (
      track.hitsNum >= min_tot_scifi_hits && track.UVhitsNum >= min_UV_scifi_hits &&
      track.XhitsNum >= min_X_scifi_hits) {

      const auto insert_index = atomicAdd(parameters.dev_scifi_lf_length_filtered_atomics + event_number, 1);

      const auto new_scifi_track_index = event_tracks_offset * maximum_number_of_candidates_per_ut_track + insert_index;

      parameters.dev_scifi_lf_length_filtered_tracks[new_scifi_track_index] = track;

      // Save track parameters to new container as well
      const auto a1 = parameters.dev_scifi_lf_parametrization[scifi_track_index];
      const auto b1 = parameters.dev_scifi_lf_parametrization
                        [total_number_of_tracks * maximum_number_of_candidates_per_ut_track + scifi_track_index];
      const auto c1 = parameters.dev_scifi_lf_parametrization
                        [2 * total_number_of_tracks * maximum_number_of_candidates_per_ut_track + scifi_track_index];
      const auto d_ratio =
        parameters.dev_scifi_lf_parametrization
          [3 * total_number_of_tracks * maximum_number_of_candidates_per_ut_track + scifi_track_index];

      parameters.dev_scifi_lf_parametrization_length_filter[new_scifi_track_index] = a1;
      parameters.dev_scifi_lf_parametrization_length_filter
        [total_number_of_tracks * maximum_number_of_candidates_per_ut_track + new_scifi_track_index] = b1;
      parameters.dev_scifi_lf_parametrization_length_filter
        [2 * total_number_of_tracks * maximum_number_of_candidates_per_ut_track + new_scifi_track_index] = c1;
      parameters.dev_scifi_lf_parametrization_length_filter
        [3 * total_number_of_tracks * maximum_number_of_candidates_per_ut_track + new_scifi_track_index] = d_ratio;
    }
  }
}

__global__ void lf_quality_filter_length::lf_quality_filter_length(
  lf_quality_filter_length::Parameters parameters,
  const unsigned maximum_number_of_candidates_per_ut_track,
  const unsigned min_tot_scifi_hits,
  const unsigned min_UV_scifi_hits,
  const unsigned min_X_scifi_hits)
{
  const auto* ut_tracks =
    Allen::dyn_cast<const Allen::Views::UT::Consolidated::MultiEventVeloUTTracks*>(*parameters.dev_tracks_view);
  if (ut_tracks) {
    quality_filter_length<true>(
      parameters,
      ut_tracks,
      maximum_number_of_candidates_per_ut_track,
      min_tot_scifi_hits,
      min_UV_scifi_hits,
      min_X_scifi_hits);
  }
  else {
    const auto* velo_tracks =
      static_cast<const Allen::Views::Velo::Consolidated::MultiEventTracks*>(*parameters.dev_tracks_view);
    quality_filter_length<false>(
      parameters,
      velo_tracks,
      maximum_number_of_candidates_per_ut_track,
      min_tot_scifi_hits,
      min_UV_scifi_hits,
      min_X_scifi_hits);
  }
}
