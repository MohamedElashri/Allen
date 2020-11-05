/*****************************************************************************\
* (c) Copyright 2018-2020 CERN for the benefit of the LHCb Collaboration      *
\*****************************************************************************/
#include "ConsolidateSciFi.cuh"

void scifi_consolidate_tracks::scifi_consolidate_tracks_t::set_arguments_size(
  ArgumentReferences<Parameters> arguments,
  const RuntimeOptions&,
  const Constants&,
  const HostBuffers&) const
{
  set_size<dev_scifi_track_hits_t>(
    arguments, first<host_accumulated_number_of_hits_in_scifi_tracks_t>(arguments) * sizeof(SciFi::Hit));
  set_size<dev_scifi_qop_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_scifi_track_ut_indices_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
  set_size<dev_scifi_states_t>(arguments, first<host_number_of_reconstructed_scifi_tracks_t>(arguments));
}

void scifi_consolidate_tracks::scifi_consolidate_tracks_t::operator()(
  const ArgumentReferences<Parameters>& arguments,
  const RuntimeOptions& runtime_options,
  const Constants&,
  HostBuffers& host_buffers,
  const Allen::Context& context) const
{
  global_function(scifi_consolidate_tracks)(dim3(size<dev_event_list_t>(arguments)), property<block_dim_t>(), context)(
    arguments);

  // Transmission device to host of Scifi consolidated tracks
  assign_to_host_buffer<dev_offsets_forward_tracks_t>(host_buffers.host_atomics_scifi, arguments, stream);

  if (runtime_options.do_check) {
    assign_to_host_buffer<dev_offsets_scifi_track_hit_number_t>(
      host_buffers.host_scifi_track_hit_number, arguments, stream);
    assign_to_host_buffer<dev_scifi_track_hits_t>(host_buffers.host_scifi_track_hits, arguments, stream);
    assign_to_host_buffer<dev_scifi_qop_t>(host_buffers.host_scifi_qop, arguments, stream);
    assign_to_host_buffer<dev_scifi_track_ut_indices_t>(host_buffers.host_scifi_track_ut_indices, arguments, stream);
    assign_to_host_buffer<dev_scifi_states_t>(host_buffers.host_scifi_states, arguments, stream);
  }
}

template<typename F>
__device__ void populate(const SciFi::TrackHits& track, const F& assign)
{
  for (int i = 0; i < track.hitsNum; i++) {
    const auto hit_index = track.hits[i];
    assign(i, hit_index);
  }
}

__global__ void scifi_consolidate_tracks::scifi_consolidate_tracks(scifi_consolidate_tracks::Parameters parameters)
{
  const unsigned event_number = parameters.dev_event_list[blockIdx.x];
  const unsigned number_of_events = parameters.dev_number_of_events[0];

  // UT consolidated tracks
  UT::Consolidated::ConstTracks ut_tracks {
    parameters.dev_atomics_ut, parameters.dev_ut_track_hit_number, event_number, number_of_events};

  const auto ut_event_tracks_offset = ut_tracks.tracks_offset(event_number);
  const auto ut_total_number_of_tracks = ut_tracks.total_number_of_tracks();

  // const SciFi::TrackHits* event_scifi_tracks =
  //   parameters.dev_scifi_tracks + ut_event_tracks_offset *
  //   LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter;
  const SciFi::TrackHits* event_scifi_tracks =
    parameters.dev_scifi_tracks + ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track;

  const unsigned total_number_of_scifi_hits =
    parameters.dev_scifi_hit_count[number_of_events * SciFi::Constants::n_mat_groups_and_mats];

  SciFi::ConstHits scifi_hits {parameters.dev_scifi_hits, total_number_of_scifi_hits};
  SciFi::ConstHitCount scifi_hit_count {parameters.dev_scifi_hit_count, event_number};

  // Create consolidated SoAs.
  SciFi::Consolidated::Tracks scifi_tracks {parameters.dev_atomics_scifi,
                                            parameters.dev_scifi_track_hit_number,
                                            parameters.dev_scifi_qop,
                                            parameters.dev_scifi_states,
                                            parameters.dev_scifi_track_ut_indices,
                                            event_number,
                                            number_of_events};
  const unsigned number_of_tracks_event = scifi_tracks.number_of_tracks(event_number);
  const unsigned event_offset = scifi_hit_count.event_offset();

  // Loop over tracks.
  for (unsigned i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {
    scifi_tracks.ut_track(i) = event_scifi_tracks[i].ut_track_index;
    scifi_tracks.qop(i) = event_scifi_tracks[i].qop;
    const auto scifi_track_index = ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track + i;

    const auto curvature = parameters.dev_scifi_lf_parametrization_consolidate[scifi_track_index];
    const auto tx = parameters.dev_scifi_lf_parametrization_consolidate
                      [ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + scifi_track_index];
    const auto x0 =
      parameters.dev_scifi_lf_parametrization_consolidate
        [2 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + scifi_track_index];
    const auto d_ratio =
      parameters.dev_scifi_lf_parametrization_consolidate
        [3 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + scifi_track_index];
    const auto y0 =
      parameters.dev_scifi_lf_parametrization_consolidate
        [4 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + scifi_track_index];
    const auto ty =
      parameters.dev_scifi_lf_parametrization_consolidate
        [5 * ut_total_number_of_tracks * SciFi::Constants::max_SciFi_tracks_per_UT_track + scifi_track_index];

    const auto dz = SciFi::Constants::ZEndT - LookingForward::z_mid_t;
    const MiniState scifi_state {x0 + tx * dz + curvature * dz * dz * (1.f + d_ratio * dz),
                                 y0 + ty * SciFi::Constants::ZEndT,
                                 SciFi::Constants::ZEndT,
                                 tx + 2.f * dz * curvature + 3.f * dz * dz * curvature * d_ratio,
                                 ty};

    scifi_tracks.states(i) = scifi_state;

    auto consolidated_hits = scifi_tracks.get_hits(parameters.dev_scifi_track_hits, i);
    const SciFi::TrackHits& track = event_scifi_tracks[i];

    // Populate arrays
    populate(track, [&consolidated_hits, &scifi_hits, &event_offset](const unsigned i, const unsigned hit_index) {
      consolidated_hits.x0(i) = scifi_hits.x0(event_offset + hit_index);
    });

    populate(track, [&consolidated_hits, &scifi_hits, &event_offset](const unsigned i, const unsigned hit_index) {
      consolidated_hits.z0(i) = scifi_hits.z0(event_offset + hit_index);
    });

    populate(track, [&consolidated_hits, &scifi_hits, &event_offset](const unsigned i, const unsigned hit_index) {
      consolidated_hits.endPointY(i) = scifi_hits.endPointY(event_offset + hit_index);
    });

    populate(track, [&consolidated_hits, &scifi_hits, &event_offset](const unsigned i, const unsigned hit_index) {
      consolidated_hits.channel(i) = scifi_hits.channel(event_offset + hit_index);
    });

    populate(track, [&consolidated_hits, &scifi_hits, &event_offset](const unsigned i, const unsigned hit_index) {
      consolidated_hits.assembled_datatype(i) = scifi_hits.assembled_datatype(event_offset + hit_index);
    });
  }
}
