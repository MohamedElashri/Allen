#include "MuonFeaturesExtraction.cuh"

__global__ void muon_catboost_features_extraction::muon_catboost_features_extraction(
  muon_catboost_features_extraction::Parameters parameters)
{
  const uint number_of_events = gridDim.x;
  const uint event_id = blockIdx.x;
  const uint station_id = blockIdx.y;

  SciFi::Consolidated::ConstTracks scifi_tracks {parameters.dev_atomics_scifi,
                                                 parameters.dev_scifi_track_hit_number,
                                                 parameters.dev_scifi_qop,
                                                 parameters.dev_scifi_states,
                                                 parameters.dev_scifi_track_ut_indices,
                                                 event_id,
                                                 number_of_events};

  const uint number_of_tracks_event = scifi_tracks.number_of_tracks(event_id);
  const uint event_offset = scifi_tracks.tracks_offset(event_id);
  for (uint track_id = threadIdx.x; track_id < number_of_tracks_event; track_id += blockDim.x) {
    float min_dist = 1e10;
    int index_of_closest_hit = -1;

    const int station_offset = parameters.dev_muon_hits[event_id].station_offsets[station_id] -
                               parameters.dev_muon_hits[event_id].station_offsets[0];
    const int number_of_hits = parameters.dev_muon_hits[event_id].number_of_hits_per_station[station_id];
    const float station_z = parameters.dev_muon_hits[event_id].z[station_offset];
    const float station_z0 = parameters.dev_muon_hits[event_id].z[0];

    const float extrapolation_x = scifi_tracks.states(track_id).x +
                                  scifi_tracks.states(track_id).tx * (station_z - scifi_tracks.states(track_id).z);
    const float extrapolation_y = scifi_tracks.states(track_id).y +
                                  scifi_tracks.states(track_id).ty * (station_z - scifi_tracks.states(track_id).z);
    const float extrapolation_x0 = scifi_tracks.states(track_id).x +
                                   scifi_tracks.states(track_id).tx * (station_z0 - scifi_tracks.states(track_id).z);
    const float extrapolation_y0 = scifi_tracks.states(track_id).y +
                                   scifi_tracks.states(track_id).ty * (station_z0 - scifi_tracks.states(track_id).z);

    for (int i_hit = 0; i_hit < number_of_hits; ++i_hit) {
      const int idx = station_offset + i_hit;

      const float dx = parameters.dev_muon_hits[event_id].x[idx] - extrapolation_x;
      const float dy = parameters.dev_muon_hits[event_id].y[idx] - extrapolation_y;
      const float hit_track_distance = dx * dx + dy * dy;

      if (hit_track_distance < min_dist) {
        // todo: possible mutex lock
        min_dist = hit_track_distance;
        index_of_closest_hit = i_hit;
      }
    }

    const uint tracks_features_offset = (event_offset + track_id) * Muon::Constants::n_catboost_features;
    if (index_of_closest_hit > -1) {
      const float common_factor = Muon::Constants::MSFACTOR * fabsf(scifi_tracks.qop(track_id));

      const int idx = station_offset + index_of_closest_hit;

      parameters.dev_muon_catboost_features[tracks_features_offset + offset::TIMES + station_id] =
        parameters.dev_muon_hits[event_id].time[idx];
      parameters.dev_muon_catboost_features[tracks_features_offset + offset::DTS + station_id] =
        parameters.dev_muon_hits[event_id].delta_time[idx];
      parameters.dev_muon_catboost_features[tracks_features_offset + offset::CROSS + station_id] =
        (parameters.dev_muon_hits[event_id].uncrossed[idx] == 0) ? 2.f :
                                                                   parameters.dev_muon_hits[event_id].uncrossed[idx];

      const float trav_dist = sqrtf(
        (station_z - station_z0) * (station_z - station_z0) +
        (extrapolation_x - extrapolation_x0) * (extrapolation_x - extrapolation_x0) +
        (extrapolation_y - extrapolation_y0) * (extrapolation_y - extrapolation_y0));
      const float errMS = common_factor * trav_dist * sqrtf(trav_dist);

      parameters.dev_muon_catboost_features[tracks_features_offset + offset::RES_X + station_id] =
        (extrapolation_x - parameters.dev_muon_hits[event_id].x[idx]) /
        sqrtf(
          (parameters.dev_muon_hits[event_id].dx[idx] * Muon::Constants::INVSQRT3) *
            (parameters.dev_muon_hits[event_id].dx[idx] * Muon::Constants::INVSQRT3) +
          errMS * errMS);
      parameters.dev_muon_catboost_features[tracks_features_offset + offset::RES_Y + station_id] =
        (extrapolation_y - parameters.dev_muon_hits[event_id].y[idx]) /
        sqrtf(
          (parameters.dev_muon_hits[event_id].dy[idx] * Muon::Constants::INVSQRT3) *
            (parameters.dev_muon_hits[event_id].dy[idx] * Muon::Constants::INVSQRT3) +
          errMS * errMS);
    }
    else {
      parameters.dev_muon_catboost_features[tracks_features_offset + offset::TIMES + station_id] = 0.f;
      parameters.dev_muon_catboost_features[tracks_features_offset + offset::DTS + station_id] = 0.f;
      parameters.dev_muon_catboost_features[tracks_features_offset + offset::CROSS + station_id] = 0.f;
      parameters.dev_muon_catboost_features[tracks_features_offset + offset::RES_X + station_id] = 0.f;
      parameters.dev_muon_catboost_features[tracks_features_offset + offset::RES_Y + station_id] = 0.f;
    }
  }
}
