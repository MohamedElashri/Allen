#include "ConsolidateSciFi.cuh"

template<typename F>
__device__ void populate(const SciFi::TrackHits& track, const F& assign)
{
  for (int i = 0; i < track.hitsNum; i++) {
    const auto hit_index = track.hits[i];
    assign(i, hit_index);
  }
};

__global__ void scifi_consolidate_tracks::scifi_consolidate_tracks(scifi_consolidate_tracks::Parameters parameters)
{
  const uint number_of_events = gridDim.x;
  const uint event_number = blockIdx.x;

  const uint ut_event_tracks_offset = parameters.dev_atomics_ut[number_of_events + event_number];
  const auto ut_total_number_of_tracks = parameters.dev_atomics_ut[2 * number_of_events];

  // const SciFi::TrackHits* event_scifi_tracks =
  //   parameters.dev_scifi_tracks + ut_event_tracks_offset *
  //   LookingForward::maximum_number_of_candidates_per_ut_track_after_x_filter;
  const SciFi::TrackHits* event_scifi_tracks =
    parameters.dev_scifi_tracks + ut_event_tracks_offset * SciFi::Constants::max_SciFi_tracks_per_UT_track;

  const uint total_number_of_scifi_hits =
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
  const uint number_of_tracks_event = scifi_tracks.number_of_tracks(event_number);
  const uint event_offset = scifi_hit_count.event_offset();

  // Loop over tracks.
  for (uint i = threadIdx.x; i < number_of_tracks_event; i += blockDim.x) {
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
    populate(track, [&consolidated_hits, &scifi_hits, &event_offset](const uint i, const uint hit_index) {
      consolidated_hits.x0(i) = scifi_hits.x0(event_offset + hit_index);
    });

    populate(track, [&consolidated_hits, &scifi_hits, &event_offset](const uint i, const uint hit_index) {
      consolidated_hits.z0(i) = scifi_hits.z0(event_offset + hit_index);
    });

    populate(track, [&consolidated_hits, &scifi_hits, &event_offset](const uint i, const uint hit_index) {
      consolidated_hits.endPointY(i) = scifi_hits.endPointY(event_offset + hit_index);
    });

    populate(track, [&consolidated_hits, &scifi_hits, &event_offset](const uint i, const uint hit_index) {
      consolidated_hits.channel(i) = scifi_hits.channel(event_offset + hit_index);
    });

    populate(track, [&consolidated_hits, &scifi_hits, &event_offset](const uint i, const uint hit_index) {
      consolidated_hits.assembled_datatype(i) = scifi_hits.assembled_datatype(event_offset + hit_index);
    });
  }
}
